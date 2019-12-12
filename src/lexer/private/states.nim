import options
import ../position, ../token, ../../utility/stack
import lexer_object, constants, context, utility
export position, token


proc transition*(self: var Lexer, state: State) =
    self.state = state
  
proc startState*(self: var Lexer) : Option[Token] =
  discard self.context.advance()
  discard self.context.advance()
  self.context.indents.push(0)
  transition self, State.IsEOF
  result = some(initToken(Indent))

proc isEOFState*(self: var Lexer) : Option[Token] =
  if self.eof:
    transition self, State.Dedent
  else:
    transition self, State.Indent

proc indentState(self: var Lexer) : Option[Token] =
  debugEcho "[Indent] Enter"
  let position = self.context.currentPosition
  # echo "indent position ", position

  if position.column != 1:
    skipWhitespace self
    transition self, State.Operator
    return

  var width = 0
  while not eof(self):
    let indentLexeme = self.appendWhile(WhitespaceChars)
    width = indentLexeme.len
    if self.matchAny(NewlineChars):
      discard self.context.advance()
    else:
      break

  if eof(self):
    transition self, State.Dedent
    return

  if not self.context.brackets.empty:
    transition self, State.Operator
    return
  
  if width > self.context.indents.top:
    self.context.indents.push width
    transition self, State.IsEOF
    return some initToken(Indent, position)
  elif width == self.context.indents.top:
    transition self, State.Operator
  else:
    transition self, State.Dedent
    return
debugEcho "[Indent] Exit"

proc dedentState(self: var Lexer) : Option[Token] =
  debugEcho "[Dedent] Enter"
  if self.context.indents.empty:
    transition self, End
    return none Token

  let target = self.lexeme.len
  if target < self.context.indents.top:
    discard self.context.indents.pop
    transition self, State.IsEOF
    result = some initToken(Dedent)
  elif target == self.context.indents.top and not self.eof:
    transition self, State.Operator
  elif target == self.context.indents.top and self.eof:
    discard self.context.indents.pop
    transition self, State.End
    result = some initToken(Dedent)
  else:
    transition self, End

  debugEcho "[Dedent] Exit"

proc operatorState(self: var Lexer) : Option[Token] =
  debugEcho "[Operator] Enter"
  self.skipWhitespace()

  let position = self.context.currentPosition

  debugEcho "Current: ", self.context.currentCharacter, " Next: ", self.context.nextCharacter
  case self.current:
    of "\n":
      debugEcho "is it newline?"
      discard self.context.advance()
      result = some initToken(Newline, position)
      transition self, IsEOF
    of "+":
      debugEcho "is it plus?"
      discard self.context.advance()
      result = some initToken(Plus, position)
      transition self, IsEOF
    of "0", "1", "2", "3", "4", "5", "6", "7", "9":
      debugEcho "is it a number?"
      transition self, State.Number
    else:
      debugEcho "no match, go to IsEOF"
      transition self, IsEOF

  # if self.matchAny(DigitChars):
  #   transition self, State.Number
  #   return

  transition self, IsEOF
  debugEcho "[Operator] Exit"

proc numberState(self: var Lexer) : Option[Token] =
  debugEcho "[Number] Enter"
  let position = self.context.currentPosition

  let number = self.appendWhile(DigitChars)
  transition self, IsEOF
  result = some initToken(Integer, position, number)
  debugEcho "[Number] Exit"

proc stringState(self: var Lexer) : Option[Token] =
  discard

proc wordState(self: var Lexer) : Option[Token] =
  discard

proc endState(self: var Lexer) : Option[Token] =
  debugEcho "[End] Enter"
  result = some(initToken(EndOfFile))
  debugEcho "[End] Exit"

template returnIfSome(lexer: var Lexer, s: State, call: proc(l: var Lexer) : Option[Token]) =
  if lexer.state == s:
    let value = call(lexer)
    if value.isSome:
      return value.get()

proc emit*(self: var Lexer) : Token =
  result = initToken(Error)

  debugEcho "Current: '", self.current, "' Next: '", self.next, "'"

  returnIfSome self, State.Start, startState
  returnIfSome self, State.IsEOF, isEOFState
  returnIfSome self, State.Indent, indentState
  returnIfSome self, State.Dedent, dedentState
  returnIfSome self, State.Operator, operatorState
  returnIfSome self, State.Number, numberState
  returnIfSome self, State.String, stringState
  returnIfSome self, State.Word, wordState
  returnIfSome self, State.End, endState
