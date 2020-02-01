import strutils

type
  AsmTokenKind* = enum
    asmError,

    asmHalt,
    asmNop,
    asmAdd,
    asmSub,
    asmMul,
    asmDiv,
    asmMod,
    asmLoadConst,
    asmStoreLocal,
    asmLoadLocal,
    asmPop,
    asmTestEqual,
    asmTestNotEqual,
    asmTestGreaterThan,
    asmTestLessThan,
    asmJump,
    asmJumpTrue,
    asmJumpFalse,
    asmCallFunc,
    asmCallInterface,
    asmReturn,
    asmNewStruct,
    asmLoadField,
    asmStoreField,

    asmAddrType,
    asmI8Type,
    asmU8Type,
    asmI16Type,
    asmU16Type,
    asmI32Type,
    asmU32Type,
    asmI64Type,
    asmU64Type,
    asmF32Type,
    asmF64Type,
    asmStringType,

    asmInteger,
    asmFloat,
    asmString,
    asmIdentifier,

    asmFunc,
    asmParam,
    asmDefine,
    asmEqual,
    asmColon,

    asmEndOfFile

  AsmToken* = object
    kind*: AsmTokenKind
    value*: string
    line*: Natural

  Lexer = object
    mode: LexerMode
    data: iterator(): char
    lineNum: int
    current: char
    lexeme: string

  LexerMode = enum
    modeDefault,
    modeNegative,
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

proc lexString*(data: string) : seq[AsmToken] =
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
        of '-':
          lexer.append()
          lexer.mode = modeNegative
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
    of modeNegative:
      case lexer.current:
        of '0':
          lexer.append()
          lexer.mode = modeDigit
        of '1', '2', '3', '4', '5', '6', '7', '8', '9':
          lexer.append()
          lexer.mode = modeDec
        else:
          result.add(AsmToken(kind: asmError, value: lexer.consume(), line: lexer.lineNum))
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
            of ".define":
              result.add(AsmToken(kind: asmDefine, value: "", line: lexer.lineNum))
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
              discard lexer.consume()
              result.add(AsmToken(kind: asmParam, line: lexer.lineNum))
            of "halt":
              discard lexer.consume()
              result.add(AsmToken(kind: asmHalt, line: lexer.lineNum))
            of "nop":
              discard lexer.consume()
              result.add(AsmToken(kind: asmNop, line: lexer.lineNum))
            of "add":
              discard lexer.consume()
              result.add(AsmToken(kind: asmAdd, line: lexer.lineNum))
            of "sub":
              discard lexer.consume()
              result.add(AsmToken(kind: asmSub, line: lexer.lineNum))
            of "mul":
              discard lexer.consume()
              result.add(AsmToken(kind: asmMul, line: lexer.lineNum))
            of "div":
              discard lexer.consume()
              result.add(AsmToken(kind: asmDiv, line: lexer.lineNum))
            of "modi":
              discard lexer.consume()
              result.add(AsmToken(kind: asmMod, line: lexer.lineNum))
            of "ldconst":
              discard lexer.consume()
              result.add(AsmToken(kind: asmLoadConst, line: lexer.lineNum))
            of "stlocal":
              discard lexer.consume()
              result.add(AsmToken(kind: asmStoreLocal, line: lexer.lineNum))
            of "ldlocal":
              discard lexer.consume()
              result.add(AsmToken(kind: asmLoadLocal, line: lexer.lineNum))
            of "pop":
              discard lexer.consume()
              result.add(AsmToken(kind: asmPop, line: lexer.lineNum))
            of "testeq":
              discard lexer.consume()
              result.add(AsmToken(kind: asmTestEqual, line: lexer.lineNum))
            of "testne":
              discard lexer.consume()
              result.add(AsmToken(kind: asmTestNotEqual, line: lexer.lineNum))
            of "testgt":
              discard lexer.consume()
              result.add(AsmToken(kind: asmTestGreaterThan, line: lexer.lineNum))
            of "testlt":
              discard lexer.consume()
              result.add(AsmToken(kind: asmTestLessThan, line: lexer.lineNum))
            of "jmp":
              discard lexer.consume()
              result.add(AsmToken(kind: asmJump, line: lexer.lineNum))
            of "jmpt":
              discard lexer.consume()
              result.add(AsmToken(kind: asmJumpTrue, line: lexer.lineNum))
            of "jmpf":
              discard lexer.consume()
              result.add(AsmToken(kind: asmJumpFalse, line: lexer.lineNum))
            of "callfunc":
              discard lexer.consume()
              result.add(AsmToken(kind: asmCallFunc, line: lexer.lineNum))
            of "callinterface":
              discard lexer.consume()
              result.add(AsmToken(kind: asmCallInterface, line: lexer.lineNum))
            of "ret":
              discard lexer.consume()
              result.add(AsmToken(kind: asmReturn, line: lexer.lineNum))
            of "newstruct":
              discard lexer.consume()
              result.add(AsmToken(kind: asmNewStruct, line: lexer.lineNum))
            of "ldfield":
              discard lexer.consume()
              result.add(AsmToken(kind: asmLoadField, line: lexer.lineNum))
            of "stfield":
              discard lexer.consume()
              result.add(AsmToken(kind: asmStoreField, line: lexer.lineNum))
            of "addr":
              discard lexer.consume()
              result.add(AsmToken(kind: asmAddrType, line: lexer.lineNum))
            of "i8":
              discard lexer.consume()
              result.add(AsmToken(kind: asmI8Type, line: lexer.lineNum))
            of "u8":
              discard lexer.consume()
              result.add(AsmToken(kind: asmU8Type, line: lexer.lineNum))
            of "i16":
              discard lexer.consume()
              result.add(AsmToken(kind: asmI16Type, line: lexer.lineNum))
            of "u16":
              discard lexer.consume()
              result.add(AsmToken(kind: asmU16Type, line: lexer.lineNum))
            of "i32":
              discard lexer.consume()
              result.add(AsmToken(kind: asmI32Type, line: lexer.lineNum))
            of "u32":
              discard lexer.consume()
              result.add(AsmToken(kind: asmU32Type, line: lexer.lineNum))
            of "i64":
              discard lexer.consume()
              result.add(AsmToken(kind: asmI64Type, line: lexer.lineNum))
            of "u64":
              discard lexer.consume()
              result.add(AsmToken(kind: asmU64Type, line: lexer.lineNum))
            of "f32":
              discard lexer.consume()
              result.add(AsmToken(kind: asmF32Type, line: lexer.lineNum))
            of "f64":
              discard lexer.consume()
              result.add(AsmToken(kind: asmF64Type, line: lexer.lineNum))
            of "str":
              discard lexer.consume()
              result.add(AsmToken(kind: asmStringType, line: lexer.lineNum))
            else:
              result.add(AsmToken(kind: asmIdentifier, value: lexer.consume(), line: lexer.lineNum))
          lexer.mode = modeDefault
  result.add(AsmToken(kind: asmEndOfFile, value: "", line: 0))

proc lexFile*(filename: string) : seq[AsmToken] =
  let file = open(filename)
  defer: file.close()
  var data = file.readAll()
  result = lexString(data)

when isMainModule:
  echo lexString(".const one = 1.i32")
