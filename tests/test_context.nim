import unittest
import caleylang/private/[context, lexer_stream], caleylang/position


suite "Context tests":
  setup:
    var stream = initLexerStreamString("Test")
    var ctx = initContext(stream)

  test "Default values":
    check:
      ctx.currentCharacter == ""
      ctx.currentPosition == initPosition(line=1, column=0)

  test "Advance returns previous character":
    let none1 = ctx.advance()
    let none2 = ctx.advance()
    let result = ctx.advance()

    check:
      none1 == ""
      none2 == ""
      result == "T"
      ctx.currentCharacter == "e"
      ctx.currentPosition == initPosition(line=1, column=2)

  test "Indent is pushed":
    let test_input = 4
    ctx.pushIndent(test_input)

    check ctx.lastIndent == test_input

  test "Indent is popped":
    let test_input = 8
    ctx.pushIndent(4)
    ctx.pushIndent(test_input)
    let result = ctx.popIndent()

    check result == test_input

  test "Bracket is pushed":
    let test_input = "("
    ctx.pushBracket(test_input)

    check ctx.lastBracket == test_input

  test "Bracket is popped":
    let test_input = ")"
    ctx.pushBracket("(")
    ctx.pushBracket(test_input)
    let result = ctx.popBracket()

    check result == test_input
  