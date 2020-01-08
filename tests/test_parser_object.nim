import options, unittest
import caleylang / [private/parser_object, token], caleylang/position


suite "Default parser":
  setup:
    let testInput = @[
      initToken(tkDecInteger, initPosition(1, 2), "42"),
      initToken(tkString, initPosition(4, 2), "Test string")
    ]
    var p = initParser(testInput)
    
    require:
      p.current.isSome
      p.next.isSome

  test "Parser instantiates":
    check:
      testInput[0] == p.current.get()
      testInput[1] == p.next.get()

  test "advance returns previous token":
    let result = p.advance()

    check testInput[0] == result.get()

  test "advance rolls tokens through":
    let expectedCurrent = testInput[1]
    let expectedNext = none Token

    discard p.advance()

    check:
      expectedCurrent == p.current.get()
      expectedNext == p.next
