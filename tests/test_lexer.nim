import lexer, token, unittest

test "Default Start state":
  var l = initLexerFromString("")

  check l.state == Start

test "Initial Indent token":
  var l = initLexerFromString("")
  let result = l.emit()

  check result.kind == TokenType.Indent

test "Closing Dedent token":
  var l = initLexerFromString("")
  discard l.emit()
  let result = l.emit()

  check result.kind == TokenType.Dedent
