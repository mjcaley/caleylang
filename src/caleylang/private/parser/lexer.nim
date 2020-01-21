import synthesis
import strutils
import context, constants, token, lexer_stream
export context, token, lexer_stream

type
  Phase = enum
    pPrime
    pBlankLines
    pIndents
    pDedents
    pBranch
    pOperator
    pStrings
    pNumber
    pWord

  Event = enum
    eStartOfLine
    eIsIndent
    eIsDigit
    eIsBinary
    eIsHexidecimal
    eIsOctal
    eIsReserved
    eIsString
    eInBrackets
    eLexemeLessThanIndent
    eLexemeEqualToIndent
    eLexemeGreaterThanIndent
    eBracketsEmpty
    eEndOfFile


# Utility procs

proc current*(self: var Context) : string =
  result = self.currentCharacter
  
proc next*(self: var Context) : string =
  result = self.nextCharacter

proc match*(self: var Context, character: string) : bool =
  result = self.current == character

proc matchAny*(self: var Context, characters: openArray[string]) : bool =
  for character in characters:
    if self.match(character):
      return true

proc matchNext*(self: var Context, character: string) : bool =
  result = self.next == character

proc matchNextAny*(self: var Context, characters: openArray[string]) : bool =
  for character in characters:
    if self.matchNext(character):
      return true

proc lexemeWhile*[T](self: var Context, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.advance())
  self.lexeme = result

proc appendWhile*[T](self: var Context, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.advance())

proc appendWhileNot*[T](self: var Context, characters: openArray[T]) : string =
  while not self.matchAny(characters) and self.currentCharacter != "":
    result.add(self.current)
    discard self.advance()

proc skip*[T](self: var Context, character: T) =
  when T is seq or T is array:
    while self.matchAny(character):
      discard self.advance()
  else:
    while self.match(character):
      discard self.advance()

proc skipWhitespace*(self: var Context) =
  self.skip(WhitespaceChars)

proc eof*(self: var Context) : bool =
  self.current == "" and self.next == ""


# Finite state machine

declareAutomaton(lexerMachine, Phase, Event)

setPrologue(lexerMachine):
  var lexeme: string

setInitialState(lexerMachine, pPrime)

setTerminalState(lexerMachine, pEnd)

# Events

implEvent(lexerMachine, eStartOfLine):
  context.currentPosition.column == 1

implEvent(lexerMachine, eEndOfFile):
  context.eof

implEvent(lexerMachine, eIsIndent):
  context.matchAny(WhitespaceChars)

implEvent(lexerMachine, eIsDigit):
  context.matchAny(DigitChars)

implEvent(lexerMachine, eIsBinary):
  context.match("0") and context.matchNext("b")

implEvent(lexerMachine, eIsHexidecimal):
  context.match("0") and context.matchNext("x")
    
implEvent(lexerMachine, eIsOctal):
  context.match("0") and context.matchNext("o")

implEvent(lexerMachine, eIsReserved):
  context.matchAny(ReservedChars)

implEvent(lexerMachine, eIsString):
  context.match("\"")

implEvent(lexerMachine, eInBrackets):
  not context.brackets.empty

implEvent(lexerMachine, eLexemeLessThanIndent):
  not context.indents.empty and lexeme.len < context.indents.top()

implEvent(lexerMachine, eLexemeEqualToIndent):
  not context.indents.empty and lexeme.len == context.indents.top()

implEvent(lexerMachine, eLexemeGreaterThanIndent):
  not context.indents.empty and lexeme.len > context.indents.top()

implEvent(lexerMachine, eBracketsEmpty):
  context.indents.empty


# State transitions
behavior(lexerMachine):
  ini: pPrime
  fin: pBlankLines
  transition:
    discard advance context
    discard advance context
    context.indents.push(0)
    tokens.add(initToken(tkIndent))

behavior(lexerMachine):
  ini: pBlankLines
  fin: pIndents
  event: eStartOfLine
  transition:
    while not context.eof:
      lexeme = context.appendWhile(IndentChars)
      if context.match "\n":
        discard advance context
      else:
        break

behavior(lexerMachine):
  ini: pBlankLines
  fin: pBranch
  transition:
    discard

behavior(lexerMachine):
  ini: [pIndents, pOperator, pWord]
  fin: pDedents
  interrupt: eEndOfFile
  transition:
    discard

onEntry(lexerMachine, [pIndents, pDedents]):
  lexeme = lexeme.replace("\t", "    ")

behavior(lexerMachine):
  ini: pIndents
  fin: pDedents
  event: eLexemeLessThanIndent
  transition:
    discard

behavior(lexerMachine):
  ini: pIndents
  fin: pBranch
  event: eLexemeEqualToIndent
  transition:
    lexeme = ""

behavior(lexerMachine):
  ini: pIndents
  fin: pBranch
  event: eLexemeGreaterThanIndent
  transition:
    let length = lexeme.len
    let pos = initPosition(
      line=context.currentPosition.line,
      column=context.currentPosition.column - length
    )
    context.indents.push(length)
    tokens.add(initToken(tkIndent, pos))
    lexeme = ""

onEntry(lexerMachine, pBranch):
  context.skipWhitespace

behavior(lexerMachine):
  ini: pBranch
  fin: pOperator
  event: eIsReserved
  transition:
    discard

behavior(lexerMachine):
  ini: pBranch
  fin: pStrings
  event: eIsString
  transition:
    discard

behavior(lexerMachine):
  ini: pBranch
  fin: pNumber
  event: eIsDigit
  transition:
    discard

behavior(lexerMachine):
  ini: pBranch
  fin: pWord
  transition:
    discard

behavior(lexerMachine):
  ini: pOperator
  fin: pBlankLines
  transition:
    let pos = context.currentPosition
    case context.currentCharacter:
      of "\n":
        tokens.add(initToken(tkNewline, pos))
        discard advance context
      of ".":
        tokens.add(initToken(tkDot, pos))
        discard advance context
      of ",":
        tokens.add(initToken(tkComma, pos))
        discard advance context
      of ":":
        tokens.add(initToken(tkColon, pos))
        discard advance context

      # Arithmetic and assignment
      of "+":
        discard advance context
        if context.match("="):
          tokens.add(initToken(tkPlusAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(tkPlus, pos))
      of "-":
        discard advance context
        if context.match("="):
          tokens.add(initToken(tkMinusAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(tkMinus, pos))
      of "*":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(tkMultiplyAssign, pos))
            discard advance context
          of "*":
            discard advance context
            case context.currentCharacter:
              of "=":
                tokens.add(initToken(tkExponentAssign, pos))
                discard advance context
              else:
                tokens.add(initToken(tkExponent, pos))
          else:
            tokens.add(initToken(tkMultiply, pos))
      of "/":
        discard advance context
        if context.match("="):
          tokens.add(initToken(tkDivideAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(tkDivide, pos))
      of "%":
        discard advance context
        if context.match("="):
          tokens.add(initToken(tkModuloAssign, pos))
          discard advance context
        else:
          tokens.add(initToken(tkModulo, pos))

      # Assignment and comparison
      of "=":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(tkEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(tkAssign, pos))
      of "<":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(tkLessThanOrEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(tkLessThan, pos))
      of ">":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(tkGreaterThanOrEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(tkGreaterThan, pos))
      of "!":
        discard advance context
        case context.currentCharacter:
          of "=":
            tokens.add(initToken(tkNotEqual, pos))
            discard advance context
          else:
            tokens.add(initToken(tkError, pos, "Expected = character after !"))

      # Brackets
      of "(":
        tokens.add(initToken(tkLeftParen, pos))
        context.brackets.push(advance context)
      of ")":
        discard advance context
        if context.brackets.pop == "(":
          tokens.add(initToken(tkRightParen, pos))
        else:
          tokens.add(initToken(tkError, pos, "Mismatched bracket; expected )"))
      of "[":
        tokens.add(initToken(tkLeftSquare, pos))
        context.brackets.push(advance context)
      of "]":
        discard advance context
        if context.brackets.pop == "[":
          tokens.add(initToken(tkRightSquare, pos))
        else:
          tokens.add(initToken(tkError, pos, "Mismatched bracket; expected ]"))
      of "{":
        tokens.add(initToken(tkLeftBrace, pos))
        context.brackets.push(advance context)
      of "}":
        discard advance context
        if context.brackets.pop == "{":
          tokens.add(initToken(tkRightBrace, pos))
        else:
          tokens.add(initToken(tkError, pos, "Mismatched bracket; expected }"))
      
      else:
        tokens.add(initToken(tkError, pos))
        discard advance context

behavior(lexerMachine):
  ini: pWord
  fin: pBlankLines
  transition:
    let pos = context.currentPosition
    let word = context.appendWhileNot(ReservedChars)

    case word:
      of "import":
        tokens.add(initToken(tkImport, pos))
      of "func":
        tokens.add(initToken(tkFunction, pos))
      of "struct":
        tokens.add(initToken(tkStruct, pos))
      of "if":
        tokens.add(initToken(tkIf, pos))
      of "elif":
        tokens.add(initToken(tkElseIf, pos))
      of "else":
        tokens.add(initToken(tkElse, pos))
      of "while":
        tokens.add(initToken(tkWhile, pos))
      of "for":
        tokens.add(initToken(tkFor, pos))
      of "and":
        tokens.add(initToken(tkAnd, pos))
      of "or":
        tokens.add(initToken(tkOr, pos))
      of "not":
        tokens.add(initToken(tkNot, pos))
      of "true":
        tokens.add(initToken(tkTrue, pos))
      of "false":
        tokens.add(initToken(tkFalse, pos))
      of "return":
        tokens.add(initToken(tkReturn, pos))
      else:
        tokens.add(initToken(tkIdentifier, pos, word))

behavior(lexerMachine):
  ini: pNumber
  fin: pBlankLines
  event: eIsBinary
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(BinaryChars)
    tokens.add(initToken(tkBinInteger, pos, number))

behavior(lexerMachine):
  ini: pNumber
  fin: pBlankLines
  event: eIsHexidecimal
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(HexChars)
    tokens.add(initToken(tkHexInteger, pos, number))

behavior(lexerMachine):
  ini: pNumber
  fin: pBlankLines
  event: eIsOctal
  transition:
    let pos = context.currentPosition
    let number = context.advance & context.advance & context.appendWhile(OctChars)
    tokens.add(initToken(tkOctInteger, pos, number))

behavior(lexerMachine):
  ini: pNumber
  fin: pBlankLines
  transition:
    let pos = context.currentPosition

    if context.match("0") and context.matchNextAny(DigitChars):
      tokens.add(initToken(tkError, pos, "Integer cannot start with a 0"))
      discard context.appendWhile(DigitChars)
    else:
      let number = context.appendWhile(DigitChars)

      if context.match(".") and context.matchNextAny(DigitChars):
        tokens.add(initToken(tkFloat, pos, number & context.advance & context.appendWhile(DigitChars)))
      else:
        tokens.add(initToken(tkDecInteger, pos, number))

behavior(lexerMachine):
  ini: pStrings
  fin: pBlankLines
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
              tokens.add(initToken(tkError, pos, "Invalid escape character"))
              break
        of "\n":
          tokens.add(initToken(tkError, pos, "Newline in middle of string"))
          break
        else:
          string_value &= advance context

    if context.match("\""):  
      tokens.add(initToken(tkString, pos, string_value))
      discard advance context
    else:
      tokens.add(initToken(tkError, pos, "String does not have closing double quote"))

behavior(lexerMachine):
  ini: pDedents
  fin: pBlankLines
  transition:
    let length = lexeme.len
    lexeme = ""
    let pos = initPosition(line=context.currentPosition.line, column=context.currentPosition.column - length)
    while context.indents.top != length:
      discard context.indents.pop
      tokens.add(initToken(tkDedent, pos))

behavior(lexerMachine):
  ini: pDedents
  fin: pEnd
  event: eEndOfFile
  transition:
    let pos = context.currentPosition

    while not context.brackets.empty:
      let bracket = context.brackets.pop
      tokens.add(initToken(tkError, pos, "Bracket " & bracket & " not closed"))

    while not context.indents.empty:
      discard context.indents.pop
      tokens.add(initToken(tkDedent, pos))

    tokens.add(initToken(tkEndOfFile, pos))


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
