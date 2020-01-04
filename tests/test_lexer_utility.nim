import unittest
import caleylang/private/[context, lexer_stream, lexer_utility]

test "current returns emptry string on first two characters":
  var c = initContext(initLexerStreamString "")

  check c.current == ""
  discard c.advance()
  check c.current == ""

suite "Empty string":
  setup:
    var c = initContext(initLexerStreamString(""))

  test "next returns empty string on first character":  
    check c.next == ""
  
suite "Next is primed with 'a'":
  setup:
    var c = initContext(initLexerStreamString("a"))
    discard c.advance()
    
  test "next returns first character":
    check c.next == "a"
    
  test "matchNext matches character":
    check c.matchNext("a") == true

  test "matchNext doesn't match character":
    check c.matchNext("b") == false

suite "Text of 'abc'":
  setup:
    var c = initContext(initLexerStreamString("abc"))
    discard c.advance()
    discard c.advance()
  
  test "current returns first character":
    check c.current == "a"

  test "match against current character":
    check c.match("a") == true

  test "Don't match against current character":
    check c.match("b") == false
  
  test "matchAny against sequence of characters":
    check c.matchAny(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]) == false

  test "Don't matchAny against sequence of characters":
    check c.matchAny(["a", "b", "c"]) == true

  test "appendWhile":
    let result = c.appendWhile(["a", "b"])

    check result == "ab"

  test "appendWhileNot":
    let result = c.appendWhileNot(["c", "d"])

    check result == "ab"

suite "Text of 'aaabc'":
  setup:
    var c = initContext(initLexerStreamString("aaabc"))
    discard c.advance()
    discard c.advance()

  test "skip single character":
    c.skip("a")

    check c.current == "b"

  test "skip multiple characters":
    c.skip(["a", "b"])

    check c.current == "c"

test "skipWhitespace":
  var c = initContext(initLexerStreamString("    abc"))
  discard c.advance()
  discard c.advance()
  c.skipWhitespace()

  check c.current == "a"

test "End of file at end":
  var c = initContext(initLexerStreamString("a"))
  discard c.advance()
  discard c.advance()
  discard c.advance()

  check c.eof() == true
