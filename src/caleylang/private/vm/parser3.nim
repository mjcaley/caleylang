import hashes, parseutils, sets, strutils, tables
import lexer

#region Parser

type
  Symbols = object
    functionSet: HashSet[FunctionDefRef]
    functions: Table[string, FunctionDef]
    constantSet: HashSet[ConstantDef]
    constants: Table[string, ConstantDef]
    labelsSet: HashSet[LabelDef]
    labels: Table[string, LabelDef]

  Parser = object
    index: int
    current: AsmToken
    tokens: iterator(): AsmToken
    errors: seq[tuple[message: string, line: int]]
    functionDefinitions: seq[FunctionDef]
    constantDefinitions: seq[ConstantDef]
    labelDefinitions: seq[LabelDef]

  FunctionDef = object
    name: string
    args: int
    locals: int
    index: int
    isDefined: bool

  FunctionDefRef = ref FunctionDef

  LabelDef = object
    name: string
    index: int
    isDefined: bool

  LabelDefRef = ref LabelDef

  ConstantDef = object
    name: string
    value: Operand
    isDefined: bool

  ConstantDefRef = ref ConstantDef

  ParseResults* = object
    program: Program
    errors: seq[tuple[message: string, line: int]]

  ParseError = object of Exception
    line: int
    message: string

  Program* = object
    functions*: seq[Function]

  Function* = object
    definition: FunctionDef
    statements*: seq[Statement]
    line*: int
  
  OperandType* = enum
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

  Constant* = object
    constant: ConstantDef
    line: int

  StatementKind* = enum
    stmtNullaryInstruction,
    stmtUnaryInstruction,
    stmtBinaryInstruction

  Statement* = object
    case kind*: StatementKind:
    of stmtNullaryInstruction:
      nullaryInstruction*: NullaryInstruction
    of stmtUnaryInstruction:
      unaryInstruction*: UnaryInstruction
    of stmtBinaryInstruction:
      binaryInstruction*: BinaryInstruction

  NullaryInstruction* = ref object
    instruction*: AsmTokenKind
    typeOf*: OperandType
    line*: int

  UnaryInstruction* = ref object
    instruction*: AsmTokenKind
    operand*: ConstantDef
    line*: int

  BinaryInstruction* = ref object
    instruction*: AsmTokenKind
    firstOperand*: ConstantDef
    secondOperand*: ConstantDef
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

const NullInstructionSize = sizeof(byte)
const UnaryInstructionSize = sizeof(byte) + sizeof(BiggestUInt)
const BinaryInstructionSize = sizeof(byte) + sizeof(BiggestUInt) + sizeof(BiggestUInt)

#region Utility

proc initConstantDef(name: string, operandValue: Operand, isDefined: bool) : ConstantDef =
  result = ConstantDef(name: name, value: operandValue, isDefined: isDefined)

proc `$`(c: ConstantDef) : string =
  result = "ConstantDef(" & c.name & ", " & $c.typeOf & ", " & $c.value & ")"

proc newFunctionDef(name: string, args, locals, index: int, isDefined: bool) : FunctionDef =
  result = new FunctionDef
  result.name = name
  result.args = args
  result.locals = locals
  result.index = index
  result.isDefined = isDefined

proc `$`(f: FunctionDef) : string =
  result = "FunctionDef(" & f.name & ", args:" & $f.args & ", locals:" & $f.locals & ", " & $f.index & ")"

proc newLabelDef(name: string, index: int, isDefined: bool) : LabelDef =
  result = new LabelDef
  result.name = name
  result.index = index
  result.isDefined = isDefined

proc `$`(l: LabelDef) : string =
  result = "LabelDef(" & l.name & ", index:" & $l.index & ")"

proc newNullaryInstruction(instruction: AsmTokenKind, typeOf: OperandType, line: int) : NullaryInstruction =
  result = new NullaryInstruction
  result.instruction = instruction
  result.typeOf = typeOf
  result.line = line

proc newUnaryInstruction(instruction: AsmTokenKind, operand: ConstantDef, line: int) : UnaryInstruction =
  result = new UnaryInstruction
  result.instruction = instruction
  result.operand = operand
  result.line = line

proc newBinaryInstruction(instruction: AsmTokenKind, first: ConstantDef, second: ConstantDef, line: int) : BinaryInstruction =
  result = new BinaryInstruction
  result.instruction = instruction
  result.firstOperand = first
  result.secondOperand = second
  result.line = line

proc initParser(tokens: seq[AsmToken]) : Parser =
  var tokenIter = iterator() : AsmToken =
    for token in tokens:
      yield token
  
  result = Parser(
    index: 0,
    tokens: tokenIter,
    current: tokenIter(),
    errors: newSeq[tuple[message: string, line: int]]()
  )

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

proc consumeIf(p: var Parser, kind: AsmTokenKind, errorMessage: string) : AsmToken =
  if p.current.kind != kind:
    raise newParseError(errorMessage, p.current.line)
  else:
    result = p.next()

proc defineLabel(p: var Parser, name: string, address: int) : LabelDef =
  for label in p.labelDefinitions:
    if label.name == name:
      raise newParseError("Lable already defined", 0)

  result = newLabelDef(name, address, true)
  p.labelDefinitions.add(result)

proc getLabelReference(p: var Parser, name: string) : LabelDef =
  for label in p.labelDefinitions:
    if label.name == name:
      result = label
  
  if result == nil:
    result = newLabelDef(name, 0, false)
    p.labelDefinitions.add(result)

#endregion

#region Symbol table

proc hash(o: Operand) : Hash =
  result = o.kind.hash
  case o.kind:
    of opFloat:
      result = result !& o.floatingPoint.hash
    of opIdentifier, opString:
      result = result !& o.value.hash
    of opSignedInteger:
      result = result !& o.sinteger.hash
    of opUnsignedInteger:
      result = result !& o.uinteger.hash
    of opVoid:
      discard
  result = !$result

proc hash(f: FunctionDef) : Hash =
  result = f.name.hash

proc hash(l: LabelDef) : Hash =
  result = l.name.hash

proc hash(c: ConstantDef) : Hash =
  result = c.value.hash

proc contains(f: Function)

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

proc operandType(p: var Parser) : OperandType =
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

proc arithmeticType(p: var Parser) : OperandType =
  let line = p.current.line
  let opType = p.operandType()
  case opType:
    of SignedIntegerTypes, UnsignedIntegerTypes, FloatingPointTypes:
      result = opType
    else:
      raise newParseError("Expected integer or floating point type", line)

proc stackOperand(p: var Parser) : tuple[typeOf: OperandType, operand: Operand] =
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

proc definitionOperand(p: var Parser) : tuple[typeOf: OperandType, operand: Operand] =
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
      p.index += 1

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
      p.index += NullInstructionSize

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
      p.index += UnaryInstructionSize

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
      p.index += UnaryInstructionSize

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
      p.index += BinaryInstructionSize
    else:
      raise newParseError("Expected instruction", p.current.line)

proc labelDefinition(p: var Parser) =
  let name = p.consumeIf(asmIdentifier, "Label name should be an identifier")
  discard p.consumeIf(asmColon, "Expected :")

  let labelDef = p.defineLabel(name.value, p.index)
  p.labelDefinitions.add(labelDef)

proc statement(p: var Parser) : Statement =
  while p.current.kind == asmIdentifier:
    p.labelDefinition()
  result = p.instructionStatement()

proc function(p: var Parser) : Function =
  let keyword = p.consumeIf(asmFunc, "Expected function keyword")
  
  let name = p.consumeIf(asmIdentifier, "Expected function name")
  
  discard p.consumeIf(asmColon, "Expected :")

  if p.current.kind != asmParam and p.current.value != "args":
    raise newParseError("Expected args parameter", p.current.line)
  discard p.next()

  discard p.consumeIf(asmEqual, "Expected =")

  let numArgs = p.consumeIf(asmInteger, "Expected integer value")

  if p.current.kind != asmParam and p.current.value != "locals":
    raise newParseError("Expected locals parameter", p.current.line)
  discard p.next()

  discard p.consumeIf(asmEqual, "Expected =")

  let numLocals = p.consumeIf(asmInteger, "Expected integer value")

  # Register definition
  let funcDef = newFunctionDef(name.value, numArgs.value.parseInt(), numLocals.value.parseInt(), p.index, true)
  p.functionDefinitions.add(funcDef)

  result = Function(definition: funcDef, statements: newSeq[Statement](), line: keyword.line)

  while not (p.current.kind in {asmFunc, asmEndOfFile}):
    try:
      result.statements.add(p.statement())
    except ParseError as e:
      p.addError(e.message, e.line)
      p.recoverTo(asmFunc, asmEndOfFile)

proc definition(p: var Parser) =
  discard p.consumeIf(asmDefine, "Expected .define keyword")
  let identifier = p.consumeIf(asmIdentifier, "Expected identifier after .define keyword")
  let op = p.definitionOperand()

  let constDef = newConstantDef(identifier.value, op.typeOf, op.operand, true)
  p.constantDefinitions.add(constDef)


proc program(p: var Parser) : Program =
  while p.current.kind != asmEndOfFile:
    try:
      case p.current.kind:
        of asmFunc:
          result.functions.add(p.function())
        of asmDefine:
          p.definition()
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
  echo "Constants ", $parser.constantDefinitions
  echo "Functions ", $parser.functionDefinitions
  echo "Labels ", $parser.labelDefinitions


when isMainModule:
  let source = """
  .define forty i32 40
  .func main: args=0, locals=0
    start:
    end:
  """
  let tokens = lexString(source)
  let parseResults = parse(tokens)
  echo "Tokens ", tokens
  echo "Errors ", parseResults.errors
