import parseutils, strutils, tables

# Lexer

type
  AsmTokenKind = enum
    asmError,
    asmInstruction,
    asmType,
    asmInteger,
    asmFloat,
    asmString,
    asmAddress,
    asmIdentifier,
    asmFunc,
    asmParam,
    asmConst,
    asmEqual,
    asmColon,
    asmEndOfFile

  AsmToken = object
    kind: AsmTokenKind
    value: string
    line: Natural

  Lexer = object
    mode: LexerMode
    data: iterator(): char
    lineNum: int
    current: char
    lexeme: string

  LexerMode = enum
    modeDefault,
    modeDigit,
    modeDec,
    modeBin,
    modeHex,
    modeFloat,
    modeString,
    modeKeyword,
    modeIdentifier


proc initLexer(data: string) : Lexer =
  result.data = iterator(): char =
    for character in data:
      yield character
  result.current = result.data()
  result.mode = modeDefault
  result.lineNum = 1
  result.lexeme = ""

proc consume(l: var Lexer) : string =
  result = l.lexeme
  l.lexeme = ""

proc next(l: var Lexer) : char =
  result = l.current
  if result == '\n':
    inc l.lineNum
  l.current = l.data()

proc append(l: var Lexer) =
  l.lexeme &= l.next()

proc lexString(data: string) : seq[AsmToken] =
  var lexer = initLexer(data)

  while true:
    case lexer.mode:
    of modeDefault:
      case lexer.current:
        of '\0':
          break
        of Whitespace:
          discard lexer.next()
        of '=':
          result.add(AsmToken(kind: asmEqual, value: "", line: lexer.lineNum))
          discard lexer.next()
        of ':':
          result.add(AsmToken(kind: asmColon, value: "", line: lexer.lineNum))
          discard lexer.next()
        of '0':
          lexer.append()
          lexer.mode = modeDigit
        of '1', '2', '3', '4', '5', '6', '7', '8', '9':
          lexer.append()
          lexer.mode = modeDec
        of '.':
          lexer.append()
          lexer.mode = modeKeyword
        of IdentStartChars:
          lexer.append()
          lexer.mode = modeIdentifier
        of '"':
          lexer.mode = modeString
          discard lexer.next()
        else:
          discard lexer.next()
    of modeDigit:
      case lexer.current:
        of 'x':
          lexer.append()
          lexer.mode = modeHex
        of 'b':
          lexer.append()
          lexer.mode = modeBin
        of '.':
          lexer.append()
          lexer.mode = modeFloat
        else:
          result.add(AsmToken(kind: asmInteger, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
    of modeDec:
      case lexer.current:
        of Digits:
          lexer.append()
        of '.':
          lexer.append()
          lexer.mode = modeFloat
        else:
          result.add(AsmToken(kind: asmInteger, value: lexer.consume(), line: lexer.lineNum))
          discard lexer.consume()
          lexer.mode = modeDefault
    of modeHex:
      case lexer.current:
        of HexDigits:
          lexer.append()
        else:
          result.add(AsmToken(kind: asmInteger, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
    of modeBin:
      case lexer.current:
        of '0', '1':
          lexer.append()
        else:
          result.add(AsmToken(kind: asmInteger, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
    of modeFloat:
      case lexer.current:
        of Digits:
          lexer.append()
        else:
          result.add(AsmToken(kind: asmFloat, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
    of modeString:
      case lexer.current:
        of '\"', Newlines:
          result.add(AsmToken(kind: asmString, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
        else:
          lexer.append()
    of modeKeyword:
      case lexer.current:
        of IdentChars:
          lexer.append()
        else:
          case lexer.lexeme:
            of ".func":
              result.add(AsmToken(kind: asmFunc, value: "", line: lexer.lineNum))
            of ".const":
              result.add(AsmToken(kind: asmConst, value: "", line: lexer.lineNum))
            of ".byte", ".addr", ".i8", ".u8", ".i16", ".u16", ".i32", ".u32", ".i64", ".u64", ".f32", ".f64":
              result.add(AsmToken(kind: asmType, value: lexer.consume(), line: lexer.lineNum))
            else:
              result.add(AsmToken(kind: asmError, value: lexer.consume(), line: lexer.lineNum))
          discard lexer.consume()
          lexer.mode = modeDefault
    of modeIdentifier:
      case lexer.current:
        of IdentChars:
          lexer.append()
        else:
          case lexer.lexeme:
            of "args", "locals":
              result.add(AsmToken(kind: asmParam, value: lexer.consume(), line: lexer.lineNum))
            of "halt", "push", "pop", "call", "ret", "newobj", "jmp", "jmpeq", "jmpne", "add", "sub", "mul", "div", "mod": 
              result.add(AsmToken(kind: asmInstruction, value: lexer.consume(), line: lexer.lineNum))
            else:
              result.add(AsmToken(kind: asmIdentifier, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
  result.add(AsmToken(kind: asmEndOfFile, value: "", line: 0))

proc lexFile(filename: string) : seq[AsmToken] =
  let file = open(filename)
  defer: file.close()
  var data = file.readAll()
  result = lexString(data)


# Parser

type
  Parser = object
    current: AsmToken
    tokens: iterator(): AsmToken
    errors: seq[tuple[message: string, line: Natural]]

  ParseError = object of Exception

  Program = object
    functions: seq[Function]
    constants: Table[string, Operand]

  Function = object
    name: string
    args: Natural
    locals: Natural
    statements: seq[Statement]
    line: Natural

  Instruction = enum
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

  InstructionType = enum
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

  StatementKind = enum
    stmtLabel,
    stmtInstruction

  Statement = object
    case kind: StatementKind:
    of stmtInstruction:
      instruction: Instruction
      typeOf: InstructionType
      operands: seq[Operand]
    of stmtLabel:
      name: string
    line: Natural

  IntegerFormat = enum
    intHex,
    intBin,
    intDec

  OperandKind = enum
    opSignedInteger,
    opUnsignedInteger,
    opFloat,
    opString,
    opConstant

  Operand = object
    case kind: OperandKind
    of opSignedInteger:
      integer: BiggestInt
    of opUnsignedInteger:
      uinteger: BiggestUInt
    of opFloat:
      floatingPoint: float64
    of opString:
      str: string
    of opConstant:
      label: string


proc initParser(tokens: seq[AsmToken]) : Parser =
  result.tokens = iterator() : AsmToken =
    for token in tokens:
      yield token
  result.current = result.tokens()
  result.errors = newSeq[tuple[message: string, line: Natural]]()

proc next(p: var Parser) : AsmToken =
  result = p.current
  p.current = p.tokens()

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
    raise newException(ParseError, "Invalid token")

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
    raise newException(ParseError, "Could not parse integer value")
  
  result = Operand(kind: opUnsignedInteger, uinteger: number)

  discard p.next()

proc signedIntegerOperand[T](p: var Parser) : Operand =
  if p.current.kind != asmInteger:
    raise newException(ParseError, "Invalid token")

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
    raise newException(ParseError, "Could not parse integer value")

  result = Operand(kind: opSignedInteger, integer: number)

  discard p.next()

proc floatOperand(p: var Parser) : Operand =
  if p.current.kind != asmFloat:
    raise newException(ParseError, "Invalid token")

  var number: float64
  let success = parseBiggestFloat(p.current.value, number)
  if success == 0:
    raise newException(ParseError, "Could not parse float value")
  
  result = Operand(kind: opFloat, floatingPoint: number)

  discard p.next()

proc stringOperand(p: var Parser) : Operand =
  if p.current.kind != asmString:
    raise newException(ParseError, "Invalid token")

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
          raise newException(ParseError, "Type didn't match")
    of asmFloat:
      case typeOf:
        of tyF32, tyF64:
          result = p.floatOperand()
        else:
          raise newException(ParseError, "Type didn't match")
    else:
      raise newException(ParseError, "Invalid type")

proc operandType(p: var Parser) : InstructionType =
  if p.current.kind != asmType:
    raise newException(ParseError, "Invalid token")
  
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
      raise newException(ParseError, "Invalid type")

proc instructionStatement(p: var Parser) : Statement =
  if p.current.kind != asmInstruction:
    raise newException(ParseError, "Invalid token")

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
          raise newException(ParseError, "Invalid type")
        else:
          result.operands.add(p.operand(instructionType))
    of insAdd, insSub, insMul, insDiv, insMod:
      let instructionType = p.operandType()
      result.typeOf = instructionType
      case instructionType:
        of tyVoid:
          raise newException(ParseError, "Invalid type")
        else:
          discard
    of insCall, insJump, insJumpEq, insJumpNEq, insNewObj:
      let instructionType = p.operandType()
      result.typeOf = instructionType
      case instructionType:
        of tyAddr:
          result.operands.add(p.operand(instructionType))
        else:
          raise newException(ParseError, "Invalid type")
  # TODO: Support constant reference

proc labelStatement(p: var Parser) : Statement =
  if p.current.kind != asmIdentifier:
    raise newException(ParseError, "Invalid token")

  let label = p.next()
  
  if p.current.kind != asmEqual:
    raise newException(ParseError, "Expected =")
  discard p.next()

  case p.current.kind:
    of asmIdentifier:
      result = Statement(kind: stmtLabel, name: p.current.value, line: label.line)
    else:
      raise newException(ParseError, "Invalid token")
  discard p.next()

proc statement(p: var Parser) : Statement =
  case p.current.kind:
    of asmInstruction:
      result = p.instructionStatement()
    of asmIdentifier:
      result = p.labelStatement()
    else:
      raise newException(ParseError, "Invalid token")

proc function(p: var Parser) : Function =
  if p.current.kind != asmFunc:
    raise newException(ParseError, "Invalid token")
  discard p.next()

  if p.current.kind != asmIdentifier:
    raise newException(ParseError, "Expected name")
  let name = p.next()

  if p.current.kind != asmColon:
    raise newException(ParseError, "Expected name")
  discard p.next()

  if p.current.kind != asmParam and p.current.value != "args":
    raise newException(ParseError, "Expected args parameter")
  discard p.next()

  if p.current.kind != asmEqual:
    raise newException(ParseError, "Expected =")
  discard p.next()

  if p.current.kind != asmInteger:
    raise newException(ParseError, "Invalid token")
  let numArgs = p.next()

  if p.current.kind != asmParam and p.current.value != "locals":
    raise newException(ParseError, "Expected locals parameter")
  discard p.next()

  if p.current.kind != asmEqual:
    raise newException(ParseError, "Expected =")
  discard p.next()

  if p.current.kind != asmInteger:
    raise newException(ParseError, "Invalid token")
  let numLocals = p.next()

  result.name = name.value
  result.args = numArgs.value.parseInt()
  result.locals = numLocals.value.parseInt()
  result.line = name.line

  while not (p.current.kind in {asmFunc, asmEndOfFile}):
    try:
      result.statements.add(p.statement())
    except ParseError:
      p.recoverTo(asmFunc, asmEndOfFile)

proc constant(p: var Parser) : tuple[name: string, value: Operand] =
  if p.current.kind != asmConst:
    raise newException(ParseError, "Invalid token")
  discard p.next()

  let typeOf = p.operandType()

  if p.current.kind != asmIdentifier:
    raise newException(ParseError, "Invalid token")
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
          raise newException(ParseError, "Invalid token")
    except ParseError:
      p.recoverTo(asmFunc, asmConst, asmEndOfFile)

proc parse(tokens: seq[AsmToken]) : Program =
  var parser = initParser(tokens)
  result = parser.program()

# .func NAME args=0 locals=0
# label_name:
# .const[.type] NAME value
# instruction[.type] e.g. push.i32, pop, add.i32
# type = byte, addr, i32, etc., str

when isMainModule:
  var line = ".func main: args=1, locals=2\npush.i32 40\npush.i32 2\nadd.i32\n"
  let tokens = lexString(line)
  echo parse(tokens)
