import context, lexer_stream, options, token, unicode, utility

type
  State* = enum
    Start,
    IsEOF,
    Indent,
    Dedent,
    Operator,
    Number,
    String,
    Word,
    End

  Lexer* = object
    context: Context
    state*: State
    lexeme: string

const IndentChars = @[" ".toRune, "\t".toRune]
const WhitespaceChars = @[
  "\v".toRune, " ".toRune, "\f".toRune,

  "\u0085".toRune, "\u00a0".toRune, "\u1680".toRune, "\u2000".toRune, "\u2001".toRune, "\u2002".toRune,
  "\u2003".toRune, "\u2004".toRune, "\u2005".toRune, "\u2006".toRune, "\u2007".toRune, "\u2008".toRune,
  "\u2009".toRune, "\u200a".toRune, "\u2028".toRune, "\u2029".toRune, "\u202f".toRune, "\u205f".toRune,
  "\u3000".toRune, "\u180e".toRune, "\u200b".toRune, "\u200c".toRune, "\u200d".toRune, "\u2060".toRune,
  "\ufeff".toRune
]
const NewlineChars = @["\n".toRune, "\r".toRune]
const ArithmeticChars = @["+".toRune, "-".toRune, "*".toRune, "/".toRune, "%".toRune]
const BracketChars = @["(".toRune, ")".toRune, "[".toRune, "]".toRune, "{".toRune, "}".toRune]
const ReservedChars = @["!".toRune, "=".toRune, "<".toRune, ">".toRune, ".".toRune, ":".toRune, ",".toRune] & 
  IndentChars & WhiteSpaceChars & NewlineChars & ArithmeticChars & BracketChars

proc initLexerFromString*(str: string) : Lexer =
  var stream = initLexerStreamString(str)
  Lexer(context: initContext(stream), state: Start)

proc initLexerFromFile*(filename: string) : Lexer =
  var stream = initLexerStreamFile(filename)
  Lexer(context: initContext(stream), state: Start)

# Utility procs
proc match(self: Lexer, character: Rune) : bool =
  if self.context.currentCharacter.isSome:
    result = self.context.currentCharacter.get() == character

proc match(self: Lexer, character: string) : bool =
  if self.context.currentCharacter.isSome:
    result = self.context.currentCharacter.get().toUTF8 == character

proc matchAny[T](self: Lexer, characters: openArray[T]) : bool =
  for character in characters:
    if self.match(character):
      return true

proc matchNext(self: Lexer, character: Rune) : bool =
  if self.context.nextCharacter.isSome:
    result = self.context.nextCharacter.get() == character

proc matchNext(self: Lexer, character: string) : bool =
  if self.context.nextCharacter.isSome:
    result = self.context.nextCharacter.get().toUTF8 == character

proc appendWhile[T](self: var Lexer, characters: openArray[T]) =
  while self.matchAny(characters):
    self.lexeme.add(self.context.currentCharacter.get())
    discard self.context.advance()

proc appendWhileNot[T](self: var Lexer, characters: openArray[T]) =
  while not self.matchAny(characters):
    self.lexeme.add(self.context.currentCharacter.get())
    discard self.context.advance()

proc skip[T](self: var Lexer, character: T) =
  when T is seq or T is array:
    if self.matchAny(character):
      discard self.context.advance()
  else:
    if self.match(character):
      discard self.context.advance()

proc skipWhitespace(self: var Lexer) =
  self.skip(WhitespaceChars)

# State procs
proc transition(self: var Lexer, state: State) =
  self.state = state

proc startState(self: var Lexer) : Option[Token] =
  discard self.context.advance()
  discard self.context.advance()
  self.context.pushIndent(0)
  transition self, IsEOF
  result = some(initToken(TokenType.Indent))

proc isEOFState(self: var Lexer) : Option[Token] =
  if self.context.currentCharacter.isNone and self.context.nextCharacter.isNone:
    transition self, Dedent
  else:
    transition self, Indent

proc indentState(self: var Lexer) : Option[Token] =
  discard

proc dedentState(self: var Lexer) : Option[Token] =
  discard

proc operatorState(self: var Lexer) : Option[Token] =
  discard

proc numberState(self: var Lexer) : Option[Token] =
  discard

proc stringState(self: var Lexer) : Option[Token] =
  discard

proc wordState(self: var Lexer) : Option[Token] =
  discard

proc endState(self: var Lexer) : Option[Token] =
  return some(initToken(EndOfFile))

template returnIfSome(function: untyped) =
  let value = function()
  if value.isSome:
    result = value.get()

proc emit*(self: var Lexer) : Token =
  case self.state:
    of Start:
      returnIfSome(self.startState)
    of IsEOF:
      returnIfSome(self.isEOFState)
    of Indent:
      returnIfSome(self.indentState)
    of Dedent:
      returnIfSome(self.dedentState)
    of Operator:
      returnIfSome(self.operatorState)
    of Number:
      returnIfSome(self.numberState)
    of String:
      returnIfSome(self.stringState)
    of Word:
      returnIfSome(self.wordState)
    of End:
      returnIfSome(self.endState)
