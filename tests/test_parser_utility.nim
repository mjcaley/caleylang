import unittest
import caleylang/private/parser/parser


test "match successful":
  let testInput = some initToken(tkIndent)

  check testInput.match(tkIndent)

test "match failed":
  let testInput = some initToken(tkIndent)

  check not testInput.match(tkDedent)

test "match multiple tokens":
  let testInput = some initToken(tkIndent)

  check testInput.match(tkIndent, tkDedent)
