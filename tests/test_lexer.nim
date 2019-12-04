import lexer, token, unittest

test "Default Start state":
  var l = initLexerFromString("")

  check l.state == State.Start

test "Initial Indent token":
  var l = initLexerFromString("")
  let result = l.emit()

  check result.kind == Indent

test "Closing Dedent token":
  var l = initLexerFromString("")
  discard l.emit()
  let result = l.emit()

  check result.kind == Dedent

test "EndOfFile token on end state":
  var l = initLexerFromString("")
  discard l.emit()
  discard l.emit()
  let result = l.emit()

  check result.kind == EndOfFile

test "Ident on whitespace":
  var l = initLexerFromString("    42")
  discard l.emit()
  let result = l.emit()

  check result.kind == Indent

test "Don't return Indnet on blank line":
  var l = initLexerFromString("    \n42")
  discard l.emit()
  let result = l.emit()

  check result.kind != Indent
