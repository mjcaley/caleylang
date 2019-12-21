import unittest
import lexer/private/[context, states, lexer_object], utility/stack


test "Lexer begins in State.Start":
  var l = initLexerFromString("")

  check l.state == State.Start
  
test "Lexer transitions to another state":
  var l = initLexerFromString("")

  check l.state == State.Start
  l.transition(State.End)
  check l.state == State.End

test "Start state advances to first character":
  var l = initLexerFromString("1")
  discard l.emit()

  check l.context.currentCharacter == "1"

test "Start state pushes indent":
  var l = initLexerFromString("")
  discard l.emit()

  check l.context.indents[l.context.indents.high] == 0

test "Start state transitions to IsEOF":
  var l = initLexerFromString("")
  discard l.emit()

  check l.state == State.IsEOF

test "Start state emits Indent token":
  var l = initLexerFromString("")
  let token = l.emit()

  check:
    token.kind == Indent

test "IsEOF state transitions to Dedent state if end of file":
  var l = initLexerFromString("")
  l.state = State.IsEOF
  l.context.indents.add(0)
  discard l.context.advance()
  discard l.context.advance()
  let token = l.emit()

  check token.kind == Dedent

test "IsEOF state transition to Indent state if not end of file":
  var l = initLexerFromString("    1")
  l.state = State.IsEOF
  l.context.indents.add(0)
  discard l.context.advance()
  discard l.context.advance()
  let token = l.emit()

  check token.kind == Indent

test "Indent state emits token at beginning of line":
  var l = initLexerFromString("    1")
  discard l.emit()
  let token = l.emit()

  check:
    token.kind == Indent
    token.position.line == 1
    token.position.column == 1

test "Indent transitions to Operator state when not at beginning of line":
  var l = initLexerFromString("    +")
  discard l.emit()
  discard l.context.advance()
  let token = l.emit()

  check:
    token.kind == Plus
    token.position.line == 1
    token.position.column == 5

test "Dedent emitted when indentation goes down":
  var l = initLexerFromString("    +")
  discard l.emit()
  l.context.indents.push(8)
  let token = l.emit()

  check:
    token.kind == Dedent
    token.position.line == 1
    token.position.column == 1

test "All Dedent tokens emitted at end of file":
  var l = initLexerFromString("    +\n")
  discard l.emit()  # Indent
  discard l.emit()  # Indent
  discard l.emit()  # Plus
  discard l.emit()  # Newline
  let dedentTok1 = l.emit()
  let dedentTok2 = l.emit()
  let eofTok = l.emit()

  check:
    dedentTok1.kind == Dedent
    dedentTok2.kind == Dedent
    eofTok.kind == EndOfFile
