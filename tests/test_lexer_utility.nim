import unittest
import lexer/private/[utility, lexer_object, context]

test "current returns emptry string on first two characters":
  var l = initLexerFromString("")

  check l.current == ""
  discard l.context.advance()
  check l.current == ""

suite "Empty string":
  setup:
    var l = initLexerFromString("")

  test "next returns empty string on first character":  
    check l.next == ""
  
suite "Next is primed with 'a'":
  setup:
    var l = initLexerFromString("a")
    discard l.context.advance()
    
  test "next returns first character":
    check l.next == "a"
    
  test "matchNext matches character":
    check l.matchNext("a") == true

  test "matchNext doesn't match character":
    check l.matchNext("b") == false

suite "Text of 'abc'":
  setup:
    var l = initLexerFromString("abc")
    discard l.context.advance()
    discard l.context.advance()
  
  test "current returns first character":
    check l.current == "a"

  test "match against current character":
    check l.match("a") == true

  test "Don't match against current character":
    check l.match("b") == false
  
  test "matchAny against sequence of characters":
    check l.matchAny(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]) == false

  test "Don't matchAny against sequence of characters":
    check l.matchAny(["a", "b", "c"]) == true

  test "lexemeWhile":
    let result = l.lexemeWhile(["a", "b"])

    check:
      result == "ab"
      l.lexeme == "ab"

  test "appendWhile":
    let result = l.appendWhile(["a", "b"])

    check result == "ab"

  test "appendWhileNot":
    let result = l.appendWhileNot(["c", "d"])

    check result == "ab"

  test "consume":
    discard l.lexemeWhile(["a", "b", "c"])
    let result = l.consume()

    check result == "abc"

suite "Text of 'aaabc'":
  setup:
    var l = initLexerFromString("aaabc")
    discard l.context.advance()
    discard l.context.advance()

  test "skip single character":
    l.skip("a")

    check l.current == "b"

  test "skip multiple characters":
    l.skip(["a", "b"])

    check l.current == "c"

test "skipWhitespace":
  var l = initLexerFromString("    abc")
  discard l.context.advance()
  discard l.context.advance()
  l.skipWhitespace()

  check l.current == "a"

test "End of file at end":
  var l = initLexerFromString("a")
  discard l.context.advance()
  discard l.context.advance()
  discard l.context.advance()

  check l.eof() == true
