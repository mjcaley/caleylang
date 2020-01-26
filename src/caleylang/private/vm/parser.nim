import parseutils, strutils, tables
import lexer

## INTEGER = ["-"] "0".."9"+
## NAME = ["_"|"a"-"z"|"A"-"Z"] ("a"-"z"|"A"-"Z")*
## FLOAT = ["-"] "0".."9"+ "." "0".."9"+
## STRING = '"' .* '"'
##
## grammar = ( function | constant )*
##
## constant = ".const" "=" value
## value = INTEGER | NAME | FLOAT | STRING
##
## function_definition = ".func" NAME ":" "args" "=" INTEGER "locals" "=" INTEGER
## function = function_definition ( statement )*
##
## statement = instruction_statement | label_statement
##
## label_statement = NAME ":"

## instruction_statement = instruction type? operand*
##
## instruction = "halt" | "nop" | "push" | "pop" | "add" | "mul" | "div" |
##               "mod" | "jmp" | "jmpeq" | "jmpneq" | "newobj" | "call" |
##               "ret"
## type = "byte" | "addr" | "i8" | "u8" | "i16" | "u16" | "i32" | "u32" |
##        "i64" | "u64" | "f32" | "f64"
##
## operand = VALUE


type
  Parser = object
    current: AsmToken
    tokens: iterator(): AsmToken
    errors: seq[tuple[message: string, line: int]]

  ParseResults* = object
    program: Program
    errors: seq[tuple[message: string, line: int]]

  ParseError = object of Exception
    line: int
    message: string

  Program* = object
    functions*: seq[Function]
    constants*: Table[string, Operand]

  Function* = object
    name*: string
    args*: int
    locals*: int
    statements*: seq[Statement]
    line*: int

  Instruction* = enum
    insHalt,
    insNop,
    insPush,
    insPop,
    insJump,
    insJumpEq,
    insJumpNEq,
    insNewObj,
    insCall,
    insRet,
    insAdd,
    insSub,
    insMul,
    insDiv,
    insMod

  InstructionType* = enum
    tyVoid,
    tyByte,
    tyAddr,
    tyI8,
    tyU8,
    tyI16,
    tyU16,
    tyI32,
    tyU32,
    tyI64,
    tyU64,
    tyF32,
    tyF64

  StatementKind* = enum
    stmtLabel,
    stmtInstruction

  Statement* = object
    case kind*: StatementKind:
    of stmtInstruction:
      instruction*: Instruction
      typeOf*: InstructionType
      operands*: seq[Operand]
    of stmtLabel:
      name*: string
    line*: int

  IntegerFormat* = enum
    intHex,
    intBin,
    intDec

  OperandKind* = enum
    opSignedInteger,
    opUnsignedInteger,
    opFloat,
    opString,
    opConstant

  Operand* = object
    case kind*: OperandKind
    of opSignedInteger:
      integer*: BiggestInt
    of opUnsignedInteger:
      uinteger*: BiggestUInt
    of opFloat:
      floatingPoint*: float64
    of opString:
      str*: string
    of opConstant:
      label*: string


proc initParser(tokens: seq[AsmToken]) : Parser =
  result.tokens = iterator() : AsmToken =
    for token in tokens:
      yield token
  result.current = result.tokens()
  result.errors = newSeq[tuple[message: string, line: int]]()

proc next(p: var Parser) : AsmToken =
  result = p.current
  p.current = p.tokens()

proc newParseError(message: string, line: int) : ref ParseError =
  result = new(ParseError)
  result.message = message
  result.line = line

proc addError(p: var Parser, message: string, line: int) =
  p.errors.add((message: message, line: line))

proc recoverTo(p: var Parser, kinds: varargs[AsmTokenKind]) =
  while not (p.current.kind in kinds):
    discard p.next()

proc intFormat(s: string) : IntegerFormat =
  if s.startsWith("0x"):
    result = intHex
  elif s.startsWith("0b"):
    result = intBin
  else:
    result = intDec

proc unsignedIntegerOperand[T](p: var Parser) : Operand =
  if p.current.kind != asmInteger:
    raise newParseError("Expected integer value", p.current.line)

  var number: T
  try:
    case intFormat(p.current.value):
      of intHex:
        number = fromHex[T](p.current.value)
      of intBin:
        number = fromBin[T](p.current.value)
      of intDec:
        number = T(parseBiggestUInt(p.current.value))
  except ValueError:
    raise newParseError("Could not convert integer value", p.current.line)
  
  result = Operand(kind: opUnsignedInteger, uinteger: number)

  discard p.next()

proc signedIntegerOperand[T](p: var Parser) : Operand =
  if p.current.kind != asmInteger:
    raise newParseError("Expected integer value", p.current.line)

  var number: T
  try:
    case intFormat(p.current.value):
      of intHex:
        number = fromBin[T](p.current.value)
      of intBin:
        number = fromBin[T](p.current.value)
      of intDec:
        number = T(parseBiggestInt(p.current.value))
  except ValueError:
    raise newParseError("Could not convert integer value", p.current.line)

  result = Operand(kind: opSignedInteger, integer: number)

  discard p.next()

proc floatOperand(p: var Parser) : Operand =
  if p.current.kind != asmFloat:
    raise newParseError("Expected float value", p.current.line)

  var number: float64
  let success = parseBiggestFloat(p.current.value, number)
  if success == 0:
    raise newParseError("Could not convert float value", p.current.line)
  
  result = Operand(kind: opFloat, floatingPoint: number)

  discard p.next()

proc stringOperand(p: var Parser) : Operand =
  if p.current.kind != asmString:
    raise newParseError("Expected string value", p.current.line)

  result = Operand(kind: opString, str: p.current.value)

  discard p.next()

proc operand(p: var Parser, typeOf: InstructionType) : Operand =
  case p.current.kind:
    of asmInteger:
      case typeOf:
        of tyByte:
          result = unsignedIntegerOperand[byte](p)
        of tyU8:
          result = unsignedIntegerOperand[uint8](p)
        of tyU16:
          result = unsignedIntegerOperand[uint16](p)
        of tyU32:
          result = unsignedIntegerOperand[uint32](p)
        of tyU64:
          result = unsignedIntegerOperand[uint64](p)
        of tyAddr:
          result = signedIntegerOperand[int](p)
        of tyI8:
          result = signedIntegerOperand[int8](p)
        of tyI16:
          result = signedIntegerOperand[int16](p)
        of tyI32:
          result = signedIntegerOperand[int32](p)
        of tyI64:
          result = signedIntegerOperand[int64](p)
        else:
          raise newParseError("Expected type didn't match found type", p.current.line)
    of asmFloat:
      case typeOf:
        of tyF32, tyF64:
          result = p.floatOperand()
        else:
          raise newParseError("Expected type didn't match found type", p.current.line)
    else:
      raise newParseError("Unexpected token type", p.current.line)

proc operandType(p: var Parser) : InstructionType =
  if p.current.kind != asmType:
    raise newParseError("Expected type declaration", p.current.line)
  
  let insType = p.next()
  case insType.value:
    of ".byte":
      result = tyByte
    of ".addr":
      result = tyAddr
    of ".i8":
      result = tyI8
    of ".u8":
      result = tyU8
    of ".i16":
      result = tyI16
    of ".u16":
      result = tyU16
    of ".i32":
      result = tyI32
    of ".u32":
      result = tyU32
    of ".i64":
      result = tyI64
    of ".u64":
      result = tyU64
    of ".f32":
      result = tyF32
    of ".f64":
      result = tyF64
    else:
      raise newParseError("Not a valid type name", p.current.line)

proc instructionStatement(p: var Parser) : Statement =
  if p.current.kind != asmInstruction:
    raise newParseError("Expected instruction", p.current.line)

  let instructionToken = p.next()
  result = Statement(kind: stmtInstruction, line: instructionToken.line)
  case instructionToken.value:
    of "halt":
      result.instruction = insHalt
    of "nop":
      result.instruction = insNop
    of "push":
      result.instruction = insPush
    of "pop":
      result.instruction = insPop
    of "jmp":
      result.instruction = insJump
    of "jmpeq":
      result.instruction = insJumpEq
    of "jmpneq":
      result.instruction = insJumpNEq
    of "newobj":
      result.instruction = insNewObj
    of "call":
      result.instruction = insCall
    of "ret":
      result.instruction = insRet
    of "add":
      result.instruction = insAdd
    of "sub":
      result.instruction = insSub
    of "mul":
      result.instruction = insMul
    of "div":
      result.instruction = insDiv
    of "mod":
      result.instruction = insMod

  case result.instruction:
    of insHalt, insNop, insPop, insRet:
      # no type, no operands
      result.typeOf = tyVoid
    of insPush:
      let instructionType = p.operandType()
      result.typeOf = instructionType
      case instructionType:
        of tyVoid:
          raise newParseError("Push instruction expects a type", p.current.line)
        else:
          result.operands.add(p.operand(instructionType))
    of insAdd, insSub, insMul, insDiv, insMod:
      let instructionType = p.operandType()
      result.typeOf = instructionType
      case instructionType:
        of tyVoid:
          raise newParseError("Instruction expects a type", p.current.line)
        else:
          discard
    of insCall, insJump, insJumpEq, insJumpNEq, insNewObj:
      let instructionType = p.operandType()
      result.typeOf = instructionType
      case instructionType:
        of tyAddr:
          result.operands.add(p.operand(instructionType))
        else:
          raise newParseError("Not a supported type", p.current.line)
  # TODO: Support constant reference

proc labelStatement(p: var Parser) : Statement =
  if p.current.kind != asmIdentifier:
    raise newParseError("Label name should be an identifier", p.current.line)

  let label = p.next()
  
  if p.current.kind != asmColon:
    raise newParseError("Expected :", p.current.line)
  discard p.next()

  result = Statement(kind: stmtLabel, name: p.current.value, line: label.line)

proc statement(p: var Parser) : Statement =
  case p.current.kind:
    of asmInstruction:
      result = p.instructionStatement()
    of asmIdentifier:
      result = p.labelStatement()
    else:
      raise newParseError("Statement should be an instruction or label", p.current.line)

proc function(p: var Parser) : Function =
  if p.current.kind != asmFunc:
    raise newParseError("Expected function keyword", p.current.line)
  discard p.next()

  if p.current.kind != asmIdentifier:
    raise newParseError("Expected function name", p.current.line)
  let name = p.next()

  if p.current.kind != asmColon:
    raise newParseError("Expected :", p.current.line)
  discard p.next()

  if p.current.kind != asmParam and p.current.value != "args":
    raise newParseError("Expected args parameter", p.current.line)
  discard p.next()

  if p.current.kind != asmEqual:
    raise newParseError("Expected =", p.current.line)
  discard p.next()

  if p.current.kind != asmInteger:
    raise newParseError("Expected integer value", p.current.line)
  let numArgs = p.next()

  if p.current.kind != asmParam and p.current.value != "locals":
    raise newParseError("Expected locals parameter", p.current.line)
  discard p.next()

  if p.current.kind != asmEqual:
    raise newParseError("Expected =", p.current.line)
  discard p.next()

  if p.current.kind != asmInteger:
    raise newParseError("Expected integer value", p.current.line)
  let numLocals = p.next()

  result.name = name.value
  result.args = numArgs.value.parseInt()
  result.locals = numLocals.value.parseInt()
  result.line = name.line

  while not (p.current.kind in {asmFunc, asmEndOfFile}):
    try:
      result.statements.add(p.statement())
    except ParseError as e:
      p.addError(e.message, e.line)
      p.recoverTo(asmFunc, asmEndOfFile)

proc constant(p: var Parser) : tuple[name: string, value: Operand] =
  if p.current.kind != asmConst:
    raise newParseError("Expected const keyword", p.current.line)
  discard p.next()

  let typeOf = p.operandType()

  if p.current.kind != asmIdentifier:
    raise newParseError("Expected identifier", p.current.line)
  let name = p.next()

  let value = p.operand(typeOf)

  result = (name.value, value)

proc program(p: var Parser) : Program =
  while p.current.kind != asmEndOfFile:
    try:
      case p.current.kind:
        of asmFunc:
          result.functions.add(p.function())
        of asmConst:
          let constantVal = p.constant()
          result.constants.add(constantVal.name, constantVal.value)
        else:
          raise newParseError("Expected function or constant", p.current.line)
    except ParseError as e:
      p.addError(e.message, e.line)
      p.recoverTo(asmFunc, asmConst, asmEndOfFile)

proc parse*(tokens: seq[AsmToken]) : ParseResults =
  var parser = initParser(tokens)
  let program = parser.program()
  result.program = program
  result.errors = parser.errors
