import options, unittest
import caleylang / [private/parser_object, token]


suite "Default parser":
  setup:
    var p = initParser(@[initToken(Indent), initToken(Dedent)])
    
    require:
      p.current.isSome
      p.next.isSome

  test "Parser instantiates":
    check:
      p.current.get().kind == Indent
      p.next.get().kind == Dedent

  test "advance returns previous token":
    let current = p.current
    let result = p.advance()

    check current == result

  test "advance rolls tokens through":
    let expectedCurrent = p.next
    let expectedNext = none Token

    discard p.advance()

    check:
      expectedCurrent == p.current
      expectedNext == p.next
