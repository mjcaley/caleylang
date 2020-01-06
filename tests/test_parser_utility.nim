import options, unittest
import caleylang/private/parser_utility, caleylang/token


test "match successful":
  let testInput = some initToken(Indent)

  check testInput.match(Indent)

test "match failed":
  let testInput = some initToken(Indent)

  check not testInput.match(Dedent)

test "match multiple tokens":
  let testInput = some initToken(Indent)

  check testInput.match(Indent, Dedent)
