import context, lexer_stream, options, position, unicode, unittest, utility

suite "Context tests":
  setup:
    var stream = initLexerStreamString("Test")
    var ctx = initContext(stream)

  test "Advance returns character":
    discard ctx.advance()
    discard ctx.advance()
    let result = ctx.advance()

    check:
      result.isSome == true
      result.get().position == ctx.currentPosition.get()
      result.get().character == ctx.currentCharacter.get()

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
    let test_input = "(".toRune
    ctx.pushBracket(test_input)

    check ctx.lastBracket == test_input

  test "Bracket is popped":
    let test_input = ")".toRune
    ctx.pushBracket("(".toRune)
    ctx.pushBracket(test_input)
    let result = ctx.popBracket()

    check result == test_input
  