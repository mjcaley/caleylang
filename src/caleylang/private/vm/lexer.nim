import strutils

type
  AsmTokenKind* = enum
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

proc lexFile*(filename: string) : seq[AsmToken] =
  let file = open(filename)
  defer: file.close()
  var data = file.readAll()
  result = lexString(data)
