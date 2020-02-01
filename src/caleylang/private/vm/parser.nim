import strutils, parseutils
import lexer

#region Parser

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
    definitions*: seq[Definition]
    functions*: seq[Function]

  Function* = object
    name*: string
    args*: int
    locals*: int
    statements*: seq[Statement]
    line*: int

  InstructionType* = enum
    tyVoid,
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
    tyF64,
    tyString

  Definition* = object
    name: string
    typeOf: InstructionType
    operand: Operand
    line: int

  StatementKind* = enum
    stmtLabel,
    stmtNullaryInstruction,
    stmtUnaryInstruction,
    stmtBinaryInstruction

  Statement* = object
    case kind*: StatementKind:
    of stmtLabel:
      label*: Label
    of stmtNullaryInstruction:
      nullaryInstruction*: NullaryInstruction
    of stmtUnaryInstruction:
      unaryInstruction*: UnaryInstruction
    of stmtBinaryInstruction:
      binaryInstruction*: BinaryInstruction

  Label* = ref object
    label*: string
    statement*: Statement
    line*: int

  NullaryInstruction* = ref object
    instruction*: AsmTokenKind
    typeOf*: InstructionType
    line*: int

  UnaryInstruction* = ref object
    instruction*: AsmTokenKind
    typeOf*: InstructionType
    operand*: Operand
    line*: int

  BinaryInstruction* = ref object
    instruction*: AsmTokenKind
    typeOf*: InstructionType
    firstOperand*: Operand
    secondOperand*: Operand
    line*: int

  OperandKind* = enum
    opVoid,
    opSignedInteger,
    opUnsignedInteger,
    opFloat,
    opString,
    opIdentifier,

  Operand* = object
    case kind*: OperandKind:
    of opVoid:
      discard
    of opSignedInteger:
      sinteger*: BiggestInt
    of opUnsignedInteger:
      uinteger*: BiggestUInt
    of opFloat:
      floatingPoint*: BiggestFloat
    of opString, opIdentifier:
      value*: string
    line*: int


const SignedIntegerTokenTypes = {asmI8Type, asmI16Type, asmI32Type, asmI64Type}
const UnsignedIntegerTokenTypes = {asmU8Type, asmU16Type, asmU32Type, asmU64Type}
const FloatingPointTokenTypes = {asmF32Type, asmF64Type}

const SignedIntegerTypes = {tyI8, tyI16, tyI32, tyI64}
const UnsignedIntegerTypes = {tyU8, tyU16, tyU32, tyU64}
const FloatingPointTypes = {tyF32, tyF64}

#region Utility

proc newNullaryInstruction(instruction: AsmTokenKind, typeOf: InstructionType, line: int) : NullaryInstruction =
  result = new NullaryInstruction
  result.instruction = instruction
  result.typeOf = typeOf
  result.line = line

proc newUnaryInstruction(instruction: AsmTokenKind, t: InstructionType, o: Operand, line: int) : UnaryInstruction =
  result = new UnaryInstruction
  result.instruction = instruction
  result.typeOf = t
  result.operand = o
  result.line = line

proc newBinaryInstruction(instruction: AsmTokenKind, t: InstructionType, first: Operand, second: Operand, line: int) : BinaryInstruction =
  result = new BinaryInstruction
  result.instruction = instruction
  result.typeOf = t
  result.firstOperand = first
  result.secondOperand = second
  result.line = line

proc newLabel(label: string, s: Statement, line: int) : Label =
  result = new Label
  result.label = label
  result.statement = s
  result.line = line

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

#endregion

proc signedIntegerOperand(p: var Parser) : Operand =
  if p.current.kind != asmInteger:
    raise newParseError("Invalid token, expected integer", p.current.line)

  let token = p.next
  var success: int
  var value: BiggestInt

  try:
    if token.value.startsWith("0x"):
      success = parseHex(token.value, value)
    elif token.value.startsWith("0b"):
      success = parseBin(token.value, value)
    else:
      success = parseBiggestInt(token.value, value)
  except ValueError:
    discard
  
  if success == 0:
    raise newParseError("Can't parse integer value", token.line)

  result = Operand(kind: opSignedInteger, sinteger: value, line: token.line)

proc unsignedIntegerOperand(p: var Parser) : Operand =
  if p.current.kind != asmInteger:
    raise newParseError("Invalid token, expected integer", p.current.line)

  let token = p.next
  var success: int
  var value: BiggestUInt
  
  try:
    if token.value.startsWith("0x"):
      success = parseHex(token.value, value)
    elif token.value.startsWith("0b"):
      success = parseBin(token.value, value)
    else:
      success = parseBiggestUInt(token.value, value)
  except ValueError:
    discard
  
  if success == 0:
    raise newParseError("Can't parse integer value", token.line)

  result = Operand(kind: opUnsignedInteger, uinteger: value, line: token.line)

proc floatOperand(p: var Parser) : Operand =
  if p.current.kind != asmFloat:
    raise newParseError("Invalid token, expected float", p.current.line)

  let token = p.next
  var value: BiggestFloat

  let success = parseBiggestFloat(token.value, value)
  
  if success == 0:
    raise newParseError("Can't parse floating point value", token.line)

  result = Operand(kind: opFloat, floatingPoint: value, line: token.line)

proc stringOperand(p: var Parser) : Operand =
  if p.current.kind != asmString:
    raise newParseError("Invalid token, expected string", p.current.line)

  let token = p.next
  result = Operand(kind: opString, value: token.value, line: token.line)

proc identifierOperand(p: var Parser) : Operand =
  if p.current.kind != asmIdentifier:
    raise newParseError("Invalid token, expected identifier", p.current.line)

  let token = p.next
  result = Operand(kind: opIdentifier, value: token.value, line: token.line)

proc operandType(p: var Parser) : InstructionType =
  case p.current.kind:
    of asmI8Type:
      result = tyI8
    of asmU8Type:
      result = tyU8
    of asmI16Type:
      result = tyI16
    of asmU16Type:
      result = tyU16
    of asmI32Type:
      result = tyI32
    of asmU32Type:
      result = tyU32
    of asmI64Type:
      result = tyI64
    of asmU64Type:
      result = tyU64
    of asmF32Type:
      result = tyF32
    of asmF64Type:
      result = tyF64
    of asmString:
      result = tyString
    else:
      raise newParseError("Not a valid type name", p.current.line)
  discard p.next()

proc arithmeticType(p: var Parser) : InstructionType =
  let line = p.current.line
  let opType = p.operandType()
  case opType:
    of SignedIntegerTypes, UnsignedIntegerTypes, FloatingPointTypes:
      result = opType
    else:
      raise newParseError("Expected integer or floating point type", line)

proc stackOperand(p: var Parser) : tuple[typeOf: InstructionType, operand: Operand] =
  case p.current.kind:
    of SignedIntegerTokenTypes:
      let opType = p.operandType()
      let op = p.signedIntegerOperand()
      result = (typeOf: opType, operand: op)

    of UnsignedIntegerTokenTypes:
      let opType = p.operandType()
      let op = p.unsignedIntegerOperand()
      result = (typeOf: opType, operand: op)

    of FloatingPointTokenTypes:
      let opType = p.operandType()
      let op = p.floatOperand()
      result = (typeOf: opType, operand: op)

    of asmString:
      let opType = p.operandType()
      let op = p.stringOperand()
      result = (typeOf: opType, operand: op)

    of asmIdentifier:
      let op = p.identifierOperand()
      result = (typeOf: tyVoid, operand: op)

    else:
      raise newParseError("Expected a type or literal", p.current.line)

proc definitionOperand(p: var Parser) : tuple[typeOf: InstructionType, operand: Operand] =
  let operandType = p.operandType()
  
  case operandType:
    of SignedIntegerTypes:
      result = (operandType, p.signedIntegerOperand())
    of UnsignedIntegerTypes:
      result = (operandType, p.unsignedIntegerOperand())
    of FloatingPointTypes:
      result = (operandType, p.floatOperand())
    of tyString:
      result = (operandType, p.stringOperand())
    else:
      raise newParseError("Expected a literal", p.current.line)

proc instructionStatement(p: var Parser) : Statement =
  case p.current.kind:
    of asmHalt, asmNop, asmPop, asmReturn, asmTestEqual, asmTestNotEqual, asmTestGreaterThan, asmTestLessThan:
      let token = p.next()
      result = Statement(
        kind: stmtNullaryInstruction,
        nullaryInstruction: newNullaryInstruction(
          token.kind,
          tyVoid,
          token.line
        )
      )

    of asmAdd, asmSub, asmMul, asmDiv, asmMod:
      let token = p.next()
      let typeOf = p.arithmeticType()
      result = Statement(
        kind: stmtNullaryInstruction,
        nullaryInstruction: newNullaryInstruction(
          token.kind,
          typeOf,
          token.line
        )
      )

    of asmLoadConst, asmStoreLocal, asmLoadLocal:
      let token = p.next()
      let operand = p.stackOperand()
      result = Statement(
        kind: stmtUnaryInstruction,
        unaryInstruction: newUnaryInstruction(
          token.kind,
          operand.typeOf,
          operand.operand,
          token.line
        )
      )

    of asmJump, asmJumpTrue, asmJumpFalse, asmCallFunc, asmCallInterface, asmNewStruct:
      let token = p.next()
      let operand = p.identifierOperand()
      result = Statement(
        kind: stmtUnaryInstruction,
        unaryInstruction: newUnaryInstruction(
          token.kind,
          tyAddr,
          operand,
          token.line
        )
      )

    of asmLoadField, asmStoreField:
      let token = p.next()
      let structDef = p.unsignedIntegerOperand()
      let fieldIndex = p.unsignedIntegerOperand()
      result = Statement(
        kind: stmtBinaryInstruction,
        binaryInstruction: newBinaryInstruction(
          token.kind,
          tyAddr,
          structDef,
          fieldIndex,
          token.line
        )
      )
    else:
      raise newParseError("Expected instruction", p.current.line)

proc statement(p: var Parser) : Statement

proc labelStatement(p: var Parser) : Statement =
  if p.current.kind != asmIdentifier:
    raise newParseError("Label name should be an identifier", p.current.line)

  let label = p.next()
  
  if p.current.kind != asmColon:
    raise newParseError("Expected :", p.current.line)
  discard p.next()

  result = Statement(
    kind: stmtLabel,
    label: newLabel(
      p.current.value,
      p.statement(),
      label.line
    )
  )

proc statement(p: var Parser) : Statement =
  case p.current.kind:
    of asmIdentifier:
      result = p.labelStatement()
    else:
      result = p.instructionStatement()

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

proc definition(p: var Parser) : Definition =
  if p.current.kind != asmDefine:
    raise newParseError("Expected define keyword", p.current.line)
  discard p.next()

  if p.current.kind != asmIdentifier:
    raise newParseError("Definition expects to have an identifier", p.current.line)
  let identifier = p.next()

  let op = p.definitionOperand()

  result = Definition(
    name: identifier.value,
    typeOf: op.typeOf,
    operand: op.operand,
    line: identifier.line
  )

proc program(p: var Parser) : Program =
  while p.current.kind != asmEndOfFile:
    try:
      case p.current.kind:
        of asmFunc:
          result.functions.add(p.function())
        of asmDefine:
          result.definitions.add(p.definition())
        else:
          raise newParseError("Expected function or constant", p.current.line)
    except ParseError as e:
      p.addError(e.message, e.line)
      p.recoverTo(asmFunc, asmDefine, asmEndOfFile)

#endregion

proc parse*(tokens: seq[AsmToken]) : ParseResults =
  var parser = initParser(tokens)
  let program = parser.program()
  result.program = program
  result.errors = parser.errors
