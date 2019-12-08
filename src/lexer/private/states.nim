import options
import ../position, ../token, ../../utility/stack
import lexer_object, constants, context, utility


proc transition*(self: var Lexer, state: State) =
    self.state = state
  
proc startState*(self: var Lexer) : Option[Token] =
  debugEcho "[Start] Enter"
  discard self.context.advance()
  discard self.context.advance()
  self.context.indents.push(0)
  transition self, State.IsEOF
  # result = some(initToken(Indent))
  debugEcho "[Start] Exit"

proc isEOFState*(self: var Lexer) : Option[Token] =
  debugEcho "[IsEOF] Enter"
  if self.eof:
    transition self, State.Dedent
  else:
    transition self, State.Indent
  debugEcho "[IsEOF] Exit"

proc indentState(self: var Lexer) : Option[Token] =
  debugEcho "[Indent] Enter"
  let position = self.context.currentPosition
  echo "indent position ", position

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
  let target = self.lexeme.len
  if target < self.context.indents.top:
    discard self.context.indents.pop
    transition self, State.IsEOF
    result = some initToken(Dedent)
  elif target == self.context.indents.top:
    transition self, State.Operator
  else:
    transition self, End
  # let targetDedent = self.lexeme.len
  # if self.context.indents.top > targetDedent:
  #   discard self.context.indents.pop()
  #   transition self, State.IsEOF
  #   result = some initToken(Dedent)
  # elif self.context.indents.top == 0 and self.eof:
  #   discard self.consume()
  #   transition self, State.End

  debugEcho "[Dedent] Exit"

proc operatorState(self: var Lexer) : Option[Token] =
  debugEcho "[Operator] Enter"
  let position = self.context.currentPosition

  case self.current:
    of "\n":
      discard self.context.advance()
      result = some initToken(Newline, position)
      transition self, IsEOF
    of "+":
      discard self.context.advance()
      result = some initToken(Plus, position)
      transition self, IsEOF
    of "0", "1", "2", "3", "4", "5", "6", "7", "9":
      transition self, State.Number
    else:
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
