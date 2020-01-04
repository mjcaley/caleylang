import strutils
import synthesis
import ../position, constants, context, lexer_stream, lexer_utility, ../token, stack


type Phase = enum
  Prime
  BlankLines
  Indents
  Dedents
  Branch
  Operator
  Strings
  Number
  Word

type Event = enum
  StartOfLine
  IsIndent
  IsDigit
  IsBinary
  IsHexidecimal
  IsOctal
  IsReserved
  IsString
  InBrackets
  LexemeLessThanIndent
  LexemeEqualToIndent
  LexemeGreaterThanIndent
  BracketsEmpty
  EndOfFile


declareAutomaton(lexerMachine, Phase, Event)

setPrologue(lexerMachine):
  var lexeme: string

setInitialState(lexerMachine, Prime)

setTerminalState(lexerMachine, End)

#Events

implEvent(lexerMachine, StartOfLine):
  context.currentPosition.column == 1

implEvent(lexerMachine, EndOfFile):
  context.eof

implEvent(lexerMachine, IsIndent):
  context.matchAny(WhitespaceChars)

implEvent(lexerMachine, IsDigit):
  context.matchAny(DigitChars)

implEvent(lexerMachine, IsBinary):
  context.match("0") and context.matchNext("b")

implEvent(lexerMachine, IsHexidecimal):
  context.match("0") and context.matchNext("x")
    
implEvent(lexerMachine, IsOctal):
  context.match("0") and context.matchNext("o")

implEvent(lexerMachine, IsReserved):
  context.matchAny(ReservedChars)

implEvent(lexerMachine, IsString):
  context.match("\"")

implEvent(lexerMachine, InBrackets):
  not context.brackets.empty

implEvent(lexerMachine, LexemeLessThanIndent):
  not context.indents.empty and lexeme.len < context.indents.top()

implEvent(lexerMachine, LexemeEqualToIndent):
  not context.indents.empty and lexeme.len == context.indents.top()

implEvent(lexerMachine, LexemeGreaterThanIndent):
  not context.indents.empty and lexeme.len > context.indents.top()

implEvent(lexerMachine, BracketsEmpty):
  context.indents.empty


# State transitions
behavior(lexerMachine):
  ini: Prime
  fin: BlankLines
  transition:
    discard advance context
    discard advance context
    context.indents.push(0)
    tokens.add(initToken(Indent))

behavior(lexerMachine):
  ini: BlankLines
  fin: Indents
  event: StartOfLine
  transition:
    while not context.eof:
      lexeme = context.appendWhile(IndentChars)
      if context.match "\n":
        discard advance context
      else:
        break

behavior(lexerMachine):
  ini: BlankLines
  fin: Branch
  transition:
    discard

behavior(lexerMachine):
  ini: [Indents, Operator, Word]
  fin: Dedents
  interrupt: EndOfFile
  transition:
    discard

onEntry(lexerMachine, [Indents, Dedents]):
  lexeme = lexeme.replace("\t", "    ")

behavior(lexerMachine):
  ini: Indents
  fin: Dedents
  event: LexemeLessThanIndent
  transition:
    discard

behavior(lexerMachine):
  ini: Indents
  fin: Branch
  event: LexemeEqualToIndent
  transition:
    lexeme = ""

behavior(lexerMachine):
  ini: Indents
  fin: Branch
  event: LexemeGreaterThanIndent
  transition:
    let length = lexeme.len
    let pos = initPosition(
      line=context.currentPosition.line,
      column=context.currentPosition.column - length
    )
    context.indents.push(length)
    tokens.add(initToken(Indent, pos))
    lexeme = ""

onEntry(lexerMachine, Branch):
  context.skipWhitespace

behavior(lexerMachine):
  ini: Branch
  fin: Operator
  event: IsReserved
  transition:
    discard

behavior(lexerMachine):
  ini: Branch
  fin: Strings
  event: IsString
  transition:
    discard

behavior(lexerMachine):
  ini: Branch
  fin: Number
  event: IsDigit
  transition:
    discard

behavior(lexerMachine):
  ini: Branch
  fin: Word
  transition:
    discard

behavior(lexerMachine):
  ini: Operator
  fin: BlankLines
  transition:
    let pos = context.currentPosition
    case context.currentCharacter:
      of "\n":
        tokens.add(initToken(Newline, pos))
        discard advance context
      of ".":
        tokens.add(initToken(Dot, pos))
        discard advance context
      of ",":
        tokens.add(initToken(Comma, pos))
        discard advance context
      of ":":
        tokens.add(initToken(Colon, pos))
        discard advance context

      # Arithmetic and assignment
      of "+":
        discard advance context
        if context.match("="):
          tokens.add(initToken(PlusAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(Plus, pos))
      of "-":
        discard advance context
        if context.match("="):
          tokens.add(initToken(MinusAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(Minus, pos))
      of "*":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(MultiplyAssign, pos))
            discard advance context
          of "*":
            discard advance context
            case context.currentCharacter:
              of "=":
                tokens.add(initToken(ExponentAssign, pos))
                discard advance context
              else:
                tokens.add(initToken(Exponent, pos))
          else:
            tokens.add(initToken(Multiply, pos))
      of "/":
        discard advance context
        if context.match("="):
          tokens.add(initToken(DivideAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(Divide, pos))
      of "%":
        discard advance context
        if context.match("="):
          tokens.add(initToken(ModuloAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(Modulo, pos))

      # Assignment and comparison
      of "=":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(Equal, pos))
            discard advance context
          else:
            tokens.add(initToken(Assign, pos))
      of "<":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(LessThanOrEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(LessThan, pos))
      of ">":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(GreaterThanOrEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(GreaterThan, pos))
      of "!":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(NotEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(Error, pos, "Expected = character after !"))

      # Brackets
      of "(":
        tokens.add(initToken(LeftParen, pos))
        context.brackets.push(advance context)
      of ")":
        discard advance context
        if context.brackets.pop == "(":
          tokens.add(initToken(RightParen, pos))
        else:
          tokens.add(initToken(Error, pos, "Mismatched bracket; expected )"))
      of "[":
        tokens.add(initToken(LeftSquare, pos))
        context.brackets.push(advance context)
      of "]":
        discard advance context
        if context.brackets.pop == "[":
          tokens.add(initToken(RightSquare, pos))
        else:
          tokens.add(initToken(Error, pos, "Mismatched bracket; expected ]"))
      of "{":
        tokens.add(initToken(LeftBrace, pos))
        context.brackets.push(advance context)
      of "}":
        discard advance context
        if context.brackets.pop == "{":
          tokens.add(initToken(RightBrace, pos))
        else:
          tokens.add(initToken(Error, pos, "Mismatched bracket; expected }"))
      
      else:
        tokens.add(initToken(Error, pos))
        discard advance context

behavior(lexerMachine):
  ini: Word
  fin: BlankLines
  transition:
    let pos = context.currentPosition
    let word = context.appendWhileNot(ReservedChars)

    case word:
      of "import":
        tokens.add(initToken(Import, pos))
      of "func":
        tokens.add(initToken(Function, pos))
      of "struct":
        tokens.add(initToken(Struct, pos))
      of "if":
        tokens.add(initToken(If, pos))
      of "elif":
        tokens.add(initToken(ElseIf, pos))
      of "else":
        tokens.add(initToken(Else, pos))
      of "while":
        tokens.add(initToken(While, pos))
      of "for":
        tokens.add(initToken(For, pos))
      of "and":
        tokens.add(initToken(And, pos))
      of "or":
        tokens.add(initToken(Or, pos))
      of "not":
        tokens.add(initToken(Not, pos))
      of "true":
        tokens.add(initToken(True, pos))
      of "false":
        tokens.add(initToken(False, pos))
      of "return":
        tokens.add(initToken(Return, pos))
      else:
        tokens.add(initToken(Identifier, pos, word))

behavior(lexerMachine):
  ini: Number
  fin: BlankLines
  event: IsBinary
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(BinaryChars)
    tokens.add(initToken(BinInteger, pos, number))

behavior(lexerMachine):
  ini: Number
  fin: BlankLines
  event: IsHexidecimal
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(HexChars)
    tokens.add(initToken(HexInteger, pos, number))

behavior(lexerMachine):
  ini: Number
  fin: BlankLines
  event: IsOctal
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(OctChars)
    tokens.add(initToken(OctInteger, pos, number))

behavior(lexerMachine):
  ini: Number
  fin: BlankLines
  transition:
    let pos = context.currentPosition

    if context.match("0") and context.matchNextAny(DigitChars):
      tokens.add(initToken(Error, pos, "Integer cannot start with a 0"))
      discard context.appendWhile(DigitChars)
      return

    let number = context.appendWhile(DigitChars)

    if context.match(".") and context.matchNextAny(DigitChars):
      tokens.add(initToken(Float, pos, number & context.advance & context.appendWhile(DigitChars)))
    else:
      tokens.add(initToken(DecInteger, pos, number))

behavior(lexerMachine):
  ini: Strings
  fin: BlankLines
  transition:
    let pos = context.currentPosition
    var string_value: string
    discard advance context

    while not context.eof():
      case context.currentCharacter:
        of "\"":
          break
        of "\\":
          case context.nextCharacter:
            of "0":
              string_value &= "\0"
              discard advance context
              discard advance context
            of "a":
              string_value &= "\a"
              discard advance context
              discard advance context
            of "b":
              string_value &= "\b"
              discard advance context
              discard advance context
            of "f":
              string_value &= "\f"
              discard advance context
              discard advance context
            of "n":
              string_value &= "\n"
              discard advance context
              discard advance context
            of "r":
              string_value &= "\r"
              discard advance context
              discard advance context
            of "t":
              string_value &= "\t"
              discard advance context
              discard advance context
            of "v":
              string_value &= "\v"
              discard advance context
              discard advance context
            of "\\":
              string_value &= "\\"
              discard advance context
              discard advance context
            of "\"":
              string_value &= "\""
              discard advance context
              discard advance context
            else:
              tokens.add(initToken(Error, pos, "Invalid escape character"))
              break
        of "\n":
          tokens.add(initToken(Error, pos, "Newline in middle of string"))
          break
        else:
          string_value &= advance context

    if context.match("\""):  
      tokens.add(initToken(String, pos, string_value))
      discard advance context
    else:
      tokens.add(initToken(Error, pos, "String does not have closing double quote"))

behavior(lexerMachine):
  ini: Dedents
  fin: BlankLines
  transition:
    let length = lexeme.len
    lexeme = ""
    let pos = initPosition(line=context.currentPosition.line, column=context.currentPosition.column - length)
    while context.indents.top != length:
      discard context.indents.pop
      tokens.add(initToken(Dedent, pos))

behavior(lexerMachine):
  ini: Dedents
  fin: End
  event: EndOfFile
  transition:
    let pos = context.currentPosition

    while not context.brackets.empty:
      let bracket = context.brackets.pop
      tokens.add(initToken(Error, pos, "Bracket " & bracket & " not closed"))

    while not context.indents.empty:
      discard context.indents.pop
      tokens.add(initToken(Dedent, pos))


synthesize(lexerMachine):
  proc observeLexer(context: var Context, tokens: var seq[Token])

proc lexFile*(filename: string) : seq[Token] =
  var stream = initLexerStreamFile(filename)
  var context = initContext(stream)
  observeLexer(context, result)

proc lexString*(str: string) : seq[Token] =
  var stream = initLexerStreamString(str)
  var context = initContext(stream)
  observeLexer(context, result)
