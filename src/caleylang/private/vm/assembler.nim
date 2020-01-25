import strutils


type
  AsmTokenKind = enum
    asmInstruction,
    asmType,
    asmInteger,
    asmFloat,
    asmAddress,
    asmLabel,
    asmFunc,
    asmArgParam,
    asmLocalParam,
    asmConst,
    asmEqual,
    asmColon,
    asmNewline

  AsmToken = object
    kind*: AsmTokenKind
    value*: string
    line*: Natural

  LexerResults = object
    errors: seq[tuple[message: string, token: AsmToken]]
    tokens: seq[AsmToken]

  AsmSize = enum
    sByte,
    sAddr,
    sInt8,
    sUint8,
    sInt16,
    sUint16,
    sInt32,
    sUint32,
    sInt64,
    sUint64,
    sFloat32,
    sFloat64


# let typedInstruction = rex"(push|add|sub|mul|div|mod)\.(byte|addr|i8|u8|i16|u16|i32|u32|i64|u64|f32|f64)"
# let untypedInstruction = rex"(halt|jmp|jmpeq|jmpne|newobj|call|ret)"
# let addressLit = rex"#(\d)+"
# let hexLit = rex"(0xd\+)"
# let intLit = rex"(\d+)"
# let funcDef = rex"\.([_a-zA-A]\w+):[ \t]*args=(\d+),[ \t]*locals=(\d+)"

proc consumeLexeme()

proc lex(data: var openArray[string]) : seq[AsmToken] =
  var lineNum = 0
  for line in data:
    inc lineNum

    for word in line.splitWhitespace():
      var lexeme: string
      for character in word:
        case character:
          of '=':
            result.add(AsmToken(kind: asmEqual, value: "", line: lineNum))
          of ':':
            result.add(AsmToken(kind: asmColon, value: "", line: lineNum))
          of '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
            
      # case word:
      #   of ".func":
      #     result.add(AsmToken(kind: asmFunc, value: "", line: lineNum))
      #     continue
      #   of ".const":
      #     result.add(AsmToken(kind: asmConst, value: "", line: lineNum))
      #     continue
      #   of "args":
      #     result.add(AsmToken(kind: asmArgParam, value: "", line: lineNum))
      #     continue
      #   of "locals":
      #     result.add(AsmToken(kind: asmLocalParam, value: "", line: lineNum))
      #     continue
      #   of "=":


# .func NAME args=0 locals=0
# label_name:
# .const[.type] NAME value
# instruction[.type] e.g. push.i32, pop, add.i32
# type = byte, addr, i32, etc., str


proc lexAsm(filename: string) : seq[AsmToken] =
  let file = open(filename)
  defer: file.close()
  var data = file.readAll().splitLines
  let tokens = lex(data)

when isMainModule:
  var line = "    .def main: args=0, locals=0\n"
  echo "'", line, "'"
  echo line.splitWhitespace()
