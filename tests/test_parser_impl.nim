import unittest
import caleylang/private/[parser_impl, parser_object, parse_tree], caleylang/[position, token]


const pos = initPosition()
const fortyTwo = initToken(DecInteger, pos, "42")

suite "Atom rule":
  test "Parses DecInteger token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses OctInteger token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses BinInteger token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses HexInteger token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses True token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses False token":
    var p = initParser(@[fortyTwo])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Parses parentheses tokens":
    var p = initParser(@[initToken(LeftParen), fortyTwo, initToken(RightParen)])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Raises exception on unexpected token between parentheses":
    var p = initParser(@[initToken LeftParen, initToken Plus, initToken RightParen])
    expect UnexpectedTokenError:
      discard p.atom()

  test "Raises exception on unexpected token":
    var p = initParser(@[initToken(Plus)])
    expect UnexpectedTokenError:
      discard p.atom()

suite "Unary expression rule":
  test "Non-matching token calls atom rule":
    var p = initParser(@[fortyTwo])
    let e = p.unaryExpression()

    check fortyTwo == e.Atom.value

  test "Parses Not token":
    let notToken = initToken(Not, pos)
    var p = initParser(@[notToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      Not == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses Plus token":
    let plusToken = initToken(Plus, pos)
    var p = initParser(@[plusToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      Plus == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses Minus token":
    let minusToken = initToken(Minus, pos)
    var p = initParser(@[minusToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      Minus == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

suite "Exponent expression rule":
  test "Non-matching token calls unary expression rule":
    var p = initParser(@[initToken(Not, pos), fortyTwo])
    let e = p.exponentExpression()

    check:
      Not == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses exponent":
    let exponent = initToken(Exponent, pos)
    var p = initParser(@[fortyTwo, exponent, fortyTwo])
    let e = p.exponentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      exponent == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses multiple exponents":
    let one = initToken(DecInteger, pos, "1")
    let two = initToken(DecInteger, pos, "2")
    let three = initToken(DecInteger, pos, "3")
    let exponent = initToken(Exponent, pos)

    var p = initParser(@[one, exponent, two, exponent, three])
    let e = p.exponentExpression()

    check:
      one == e.BinaryExpression.left.BinaryExpression.left.Atom.value
      exponent == e.BinaryExpression.left.BinaryExpression.operator
      two == e.BinaryExpression.left.BinaryExpression.right.Atom.value
      exponent == e.BinaryExpression.operator
      three == e.BinaryExpression.right.Atom.value

suite "Product expression rule":
  test "Non-matching token calls exponent expression rule":
    let one = initToken(DecInteger, pos, "1")
    let exponent = initToken(Exponent, pos)
    let two = initToken(DecInteger, pos, "2")
    var p = initParser(@[one, exponent, two])
    let e = p.productExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      exponent == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses multiply":
    let multiply = initToken(Multiply, pos)
    var p = initParser(@[fortyTwo, multiply, fortyTwo])
    let e = p.productExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      multiply == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses divide":
    let divide = initToken(Divide, pos)
    var p = initParser(@[fortyTwo, divide, fortyTwo])
    let e = p.productExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      divide == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value      

  test "Parses modulo":
    let modulo = initToken(Modulo, pos)
    var p = initParser(@[fortyTwo, modulo, fortyTwo])
    let e = p.productExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      modulo == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value   

  test "Parses multiple multiply operators":
    let one = initToken(DecInteger, pos, "1")
    let two = initToken(DecInteger, pos, "2")
    let three = initToken(DecInteger, pos, "3")
    let four = initToken(DecInteger, pos, "4")
    let multiply = initToken(Multiply, pos)
    let divide = initToken(Divide, pos)
    let modulo = initToken(Modulo, pos)

    var p = initParser(@[one, multiply, two, divide, three, modulo, four])
    let e = p.productExpression()

    check:
      one ==      e.BinaryExpression.left.BinaryExpression.left.BinaryExpression.left.Atom.value
      multiply == e.BinaryExpression.left.BinaryExpression.left.BinaryExpression.operator
      two ==      e.BinaryExpression.left.BinaryExpression.left.BinaryExpression.right.Atom.value
      divide ==   e.BinaryExpression.left.BinaryExpression.operator
      three ==    e.BinaryExpression.left.BinaryExpression.right.Atom.value
      modulo ==   e.BinaryExpression.operator
      four ==     e.BinaryExpression.right.Atom.value

suite "Expression rule":
  test "Parses Atom":
    var p = initParser(@[fortyTwo])
    let e = Atom(p.expression())  

    check fortyTwo == e.value

suite "Statement rule":
  test "Parses ExpressionStatement":
    var p = initParser(@[fortyTwo])
    let statement = p.statement()

    check fortyTwo == statement.ExpressionStatement.expression.Atom.value

suite "Statements rule":
  test "Parses one token":
    var p = initParser(@[fortyTwo])
    let statements = p.statements()

    check fortyTwo == statements[0].ExpressionStatement.expression.Atom.value

  test "Parses multiple tokens":
    let expected1 = fortyTwo
    let expected2 = initToken(String, pos, "Test string")
    var p = initParser(@[expected1, expected2])
    let statements = p.statements()

    check:
      expected1 == statements[0].ExpressionStatement.expression.Atom.value
      expected2 == statements[1].ExpressionStatement.expression.Atom.value

suite "Start rule":
  test "Start":
    var p = initParser(@[fortyTwo])
    let start = p.start()

    check fortyTwo == start.statements[0].ExpressionStatement.expression.Atom.value
