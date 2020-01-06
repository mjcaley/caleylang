import unittest
import caleylang/private/[parser_impl, parser_object, parse_tree], caleylang/[position, token]


const pos = initPosition()

suite "Atom rule":
  test "Parses DecInteger token":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses OctInteger token":
    let expected = initToken(OctInteger, pos, "0o42")
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses BinInteger token":
    let expected = initToken(BinInteger, pos, "0b101")
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses HexInteger token":
    let expected = initToken(HexInteger, pos, "0x42")
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses True token":
    let expected = initToken(True, pos)
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses False token":
    let expected = initToken(False, pos)
    var p = initParser(@[expected])
    let a = p.atom()

    check expected == a.Atom.value

  test "Parses parentheses tokens":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[initToken(LeftParen), expected, initToken(RightParen)])
    let a = p.atom()

    check expected == a.Atom.value

  test "Raises exception on unexpected token between parentheses":
    var p = initParser(@[initToken LeftParen, initToken Plus, initToken RightParen])
    expect UnexpectedTokenError:
      discard p.atom()

  test "Raises exception on unexpected token":
    var p = initParser(@[initToken(Plus)])
    expect UnexpectedTokenError:
      discard p.atom()

suite "Expression rule":
  test "Parses Atom":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[expected])
    let e = Atom(p.expression())  

    check expected == e.value

suite "Statement rule":
  test "Parses ExpressionStatement":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[expected])
    let statement = p.statement()

    check expected == statement.ExpressionStatement.expression.Atom.value

suite "Statements rule":
  test "Parses one token":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[expected])
    let statements = p.statements()

    check expected == statements[0].ExpressionStatement.expression.Atom.value

  test "Parses multiple tokens":
    let expected1 = initToken(DecInteger, pos, "42")
    let expected2 = initToken(String, pos, "Test string")
    var p = initParser(@[expected1, expected2])
    let statements = p.statements()

    check:
      expected1 == statements[0].ExpressionStatement.expression.Atom.value
      expected2 == statements[1].ExpressionStatement.expression.Atom.value

suite "Start rule":
  test "Start":
    let expected = initToken(DecInteger, pos, "42")
    var p = initParser(@[expected])
    let start = p.start()

    check expected == start.statements[0].ExpressionStatement.expression.Atom.value
