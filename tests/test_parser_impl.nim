import unittest
import caleylang/private/parser/parser
import caleylang/parse_tree_printer


const pos = initPosition()
const fortyTwo = initToken(tkDecInteger, pos, "42")

suite "Error recovery":
  test "Recover to next statement":
    var expected = initToken(tkDecInteger, pos, "1")
    var p = initParser(@[fortyTwo, initToken(tkNewline), expected, initToken(tkEndOfFile)])
    p.recoverToNextStatement()

    require p.current.isSome()
    check expected == p.current.get()

  test "Recover to next block":
    var expected = initToken(tkDecInteger, pos, "1")
    var p = initParser(@[fortyTwo, initToken(tkDedent), expected, initToken(tkEndOfFile)])
    p.recoverToNextBlock()

    require p.current.isSome()
    check expected == p.current.get()

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
    var p = initParser(@[initToken(tkLeftParen), fortyTwo, initToken(tkRightParen)])
    let a = p.atom()

    check fortyTwo == a.Atom.value

  test "Raises exception on unexpected token between parentheses":
    var p = initParser(@[initToken tkLeftParen, initToken tkPlus, initToken tkRightParen])
    expect UnexpectedTokenError:
      discard p.atom()

  test "Raises exception on unexpected token":
    var p = initParser(@[initToken(tkPlus)])
    expect UnexpectedTokenError:
      discard p.atom()

suite "Unary expression rule":
  test "Non-matching token calls postfix expression rule":
    var p = initParser(@[fortyTwo])
    let e = p.unaryExpression()

    check fortyTwo == e.Atom.value

  test "Parses Not token":
    let notToken = initToken(tkNot, pos)
    var p = initParser(@[notToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      tkNot == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses Plus token":
    let plusToken = initToken(tkPlus, pos)
    var p = initParser(@[plusToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      tkPlus == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses Minus token":
    let minusToken = initToken(tkMinus, pos)
    var p = initParser(@[minusToken, fortyTwo])
    let e = p.unaryExpression()

    check:
      tkMinus == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

suite "Exponent expression rule":
  test "Non-matching token calls unary expression rule":
    var p = initParser(@[initToken(tkNot, pos), fortyTwo])
    let e = p.exponentExpression()

    check:
      tkNot == e.UnaryExpression.operator.kind
      fortyTwo == e.UnaryExpression.operand.Atom.value

  test "Parses exponent":
    let exponent = initToken(tkExponent, pos)
    var p = initParser(@[fortyTwo, exponent, fortyTwo])
    let e = p.exponentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      exponent == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses multiple exponents":
    let one = initToken(tkDecInteger, pos, "1")
    let two = initToken(tkDecInteger, pos, "2")
    let three = initToken(tkDecInteger, pos, "3")
    let exponent = initToken(tkExponent, pos)

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
    let one = initToken(tkDecInteger, pos, "1")
    let exponent = initToken(tkExponent, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, exponent, two])
    let e = p.productExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      exponent == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses multiply":
    let multiply = initToken(tkMultiply, pos)
    var p = initParser(@[fortyTwo, multiply, fortyTwo])
    let e = p.productExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      multiply == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses divide":
    let divide = initToken(tkDivide, pos)
    var p = initParser(@[fortyTwo, divide, fortyTwo])
    let e = p.productExpression()

    printTree(e)

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      divide == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses modulo":
    let modulo = initToken(tkModulo, pos)
    var p = initParser(@[fortyTwo, modulo, fortyTwo])
    let e = p.productExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      modulo == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses multiple multiply operators":
    let one = initToken(tkDecInteger, pos, "1")
    let two = initToken(tkDecInteger, pos, "2")
    let three = initToken(tkDecInteger, pos, "3")
    let four = initToken(tkDecInteger, pos, "4")
    let multiply = initToken(tkMultiply, pos)
    let divide = initToken(tkDivide, pos)
    let modulo = initToken(tkModulo, pos)

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

suite "Sum expression rule":
  test "Non-matching token calls product expression rule":
    let one = initToken(tkDecInteger, pos, "1")
    let operator = initToken(tkMultiply, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, operator, two])
    let e = p.sumExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses addition":
    let operator = initToken(tkPlus, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.sumExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses subtraction":
    let operator = initToken(tkMinus, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.sumExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses multiple sum operators":
    let one = initToken(tkDecInteger, pos, "1")
    let two = initToken(tkDecInteger, pos, "2")
    let three = initToken(tkDecInteger, pos, "3")
    let operator1 = initToken(tkPlus, pos)
    let operator2 = initToken(tkMinus, pos)

    var p = initParser(@[one, operator1, two, operator2, three])
    let e = p.sumExpression()

    check:
      one ==        e.BinaryExpression.left.BinaryExpression.left.Atom.value
      operator1 ==  e.BinaryExpression.left.BinaryExpression.operator
      two ==        e.BinaryExpression.left.BinaryExpression.right.Atom.value
      operator2 ==  e.BinaryExpression.operator
      three ==      e.BinaryExpression.right.Atom.value

suite "And expression rule":
  test "Non-matching token calls sum expression rule":
    let one = initToken(tkDecInteger, pos, "1")
    let operator = initToken(tkPlus, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, operator, two])
    let e = p.andExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses and":
    let operator = initToken(tkAnd, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.andExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

suite "Or expression rule":
  test "Non-matching token calls and expression rule":
    let one = initToken(tkDecInteger, pos, "1")
    let operator = initToken(tkAnd, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, operator, two])
    let e = p.orExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses or":
    let operator = initToken(tkOr, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.orExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

suite "Compare expression rule":
  test "Non-matching token calls or expression rule":
    let one = initToken(tkDecInteger, pos, "1")
    let operator = initToken(tkOr, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, operator, two])
    let e = p.compareExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses equal":
    let operator = initToken(tkEqual, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses not equal":
    let operator = initToken(tkNotEqual, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses less than":
    let operator = initToken(tkLessThan, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses greater than":
    let operator = initToken(tkGreaterThan, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses less than or equal":
    let operator = initToken(tkLessThanOrEqual, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses greater than or equal":
    let operator = initToken(tkGreaterThanOrEqual, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.compareExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

suite "Assignment expression rule":
  test "Non-matching token calls compare expression rule":
    let one = initToken(tkDecInteger, pos, "1")
    let operator = initToken(tkEqual, pos)
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[one, operator, two])
    let e = p.assignmentExpression()

    check:
      one == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      two == e.BinaryExpression.right.Atom.value

  test "Parses assign":
    let operator = initToken(tkAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses assign addition":
    let operator = initToken(tkPlusAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses assign subtraction":
    let operator = initToken(tkMinusAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses assign multiplication":
    let operator = initToken(tkMultiplyAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses assign division":
    let operator = initToken(tkDivideAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

  test "Parses assign exponent":
    let operator = initToken(tkExponentAssign, pos)
    var p = initParser(@[fortyTwo, operator, fortyTwo])
    let e = p.assignmentExpression()

    check:
      fortyTwo == e.BinaryExpression.left.Atom.value
      operator == e.BinaryExpression.operator
      fortyTwo == e.BinaryExpression.right.Atom.value

suite "Postfix expression rule":
  test "Non-matching token calls atom expression rule":
    var p = initParser(@[fortyTwo])
    let e = p.postfixExpression()

    check fortyTwo == e.Atom.value

  test "Parses field access":
    let one = initToken(tkDecInteger, pos, "1")
    let field = initToken(tkIdentifier, pos, "field")
    var p = initParser(@[one, initToken(tkDot, pos), field])
    let e = p.postfixExpression()

    check:
      one == e.FieldAccessExpression.operand.Atom.value
      field == e.FieldAccessExpression.field

  test "Field access without Identifier token raises exception":
    let one = initToken(tkIdentifier, pos, "one")
    var p = initParser(@[one, initToken(tkDot), fortyTwo])
    
    expect UnexpectedTokenError:
      discard p.postfixExpression()
    
  test "Parses empty call":
    let one = initToken(tkDecInteger, pos, "1")
    var p = initParser(@[one, initToken(tkLeftParen), initToken(tkRightParen)])
    let e = p.postfixExpression()

    check:
      one == e.CallExpression.operand.Atom.value
      0 == len(e.CallExpression.parameters)

  test "Parses call with one parameter":
    let one = initToken(tkDecInteger, pos, "1")
    var p = initParser(@[fortyTwo, initToken(tkLeftParen), one, initToken(tkRightParen)])
    let e = p.postfixExpression()

    check:
      fortyTwo == e.CallExpression.operand.Atom.value
      1 == len(e.CallExpression.parameters)
      one == e.CallExpression.parameters[0].Atom.value

  test "Parses call with multiple parameters":
    let one = initToken(tkDecInteger, pos, "1")
    let two = initToken(tkDecInteger, pos, "2")
    var p = initParser(@[fortyTwo, initToken(tkLeftParen), one, initToken(tkComma), two, initToken(tkRightParen)])
    let e = p.postfixExpression()

    check:
      fortyTwo == e.CallExpression.operand.Atom.value
      2 == len(e.CallExpression.parameters)
      one == e.CallExpression.parameters[0].Atom.value
      two == e.CallExpression.parameters[1].Atom.value

  test "Call without matching right parentheses raises exception":
    let one = initToken(tkIdentifier, pos, "one")
    var p = initParser(@[one, initToken(tkLeftParen), one])

    expect UnexpectedTokenError:
      discard p.postfixExpression()

  test "Parses subscript":
    let one = initToken(tkDecInteger, pos, "1")
    var p = initParser(@[fortyTwo, initToken(tkLeftSquare), one, initToken(tkRightSquare)])
    let e = p.postfixExpression()

    check:
      fortyTwo == e.SubscriptExpression.operand.Atom.value
      one == e.SubscriptExpression.subscript.Atom.value

  test "Subscript raises exception when there is no matching right square bracket":
    let one = initToken(tkIdentifier, pos, "one")
    var p = initParser(@[one, initToken(tkLeftSquare), fortyTwo])
    
    expect UnexpectedTokenError:
      discard p.postfixExpression()

  test "Parses multiple postfix expressions":
    let one = initToken(tkDecInteger, pos, "1")
    let two = initToken(tkIdentifier, pos, "two")
    let three = initToken(tkDecInteger, pos, "3")
    var p = initParser(@[fortyTwo, initToken(tkLeftParen), one, initToken(tkRightParen), initToken(tkDot), two, initToken(tkLeftSquare), three, initToken(tkRightSquare)])
    let e = p.postfixExpression()

    check:
      # Expected tree:
      # [SubscriptExpression]
      #   subscript
      #     Atom(three)
      #   operand
      #     [FieldAccessExpression]
      #       field
      #         Atom(two)
      #       operand
      #         [CallExpression]
      #           operand
      #             Atom(fortyTwo)
      #           parameters
      #             [ Atom(one) ]
      three == e.SubscriptExpression.subscript.Atom.value
      two == e.SubscriptExpression.operand.FieldAccessExpression.field
      1 == len(e.SubscriptExpression.operand.FieldAccessExpression.operand.CallExpression.parameters)
      one == e.SubscriptExpression.operand.FieldAccessExpression.operand.CallExpression.parameters[0].Atom.value
      fortyTwo == e.SubscriptExpression.operand.FieldAccessExpression.operand.CallExpression.operand.Atom.value

suite "Expression rule":
  test "Parses expression":
    var p = initParser(@[fortyTwo])
    let e = p.expression()

    check fortyTwo == e.Atom.value

suite "Statement rule":
  test "Parses ExpressionStatement ending in newline":
    var p = initParser(@[fortyTwo, initToken(tkNewline)])
    let statement = p.statement()

    check fortyTwo == statement.ExpressionStatement.expression.Atom.value

  test "Parses ExpresionStatement ending in dedent":
    var p = initParser(@[fortyTwo, initToken(tkDedent)])
    let statement = p.statement()

    check fortyTwo == statement.ExpressionStatement.expression.Atom.value

  test "Parses ImportStatement of one module":
    let one = initToken(tkIdentifier, pos, "one")
    var p = initParser(@[initToken(tkImport), one, initToken(tkNewline)])
    let s = p.statement()

    check:
      1 == len(s.ImportStatement.modules)
      one == s.ImportStatement.modules[0]

  test "Parses ImportStatement of multiple modules":
    let one = initToken(tkIdentifier, pos, "one")
    let two = initToken(tkIdentifier, pos, "two")
    var p = initParser(@[initToken(tkImport), one, initToken(tkComma), two, initToken(tkNewline)])
    let s = p.statement()

    check:
      2 == len(s.ImportStatement.modules)
      one == s.ImportStatement.modules[0]
      two == s.ImportStatement.modules[1]

suite "Statements rule":
  test "Parses one token":
    var p = initParser(@[initToken(tkIndent), fortyTwo, initToken(tkNewline), initToken(tkDedent)])
    let statements = p.statements()

    check fortyTwo == statements[0].ExpressionStatement.expression.Atom.value

  test "Parses multiple tokens":
    let expected1 = fortyTwo
    let expected2 = initToken(tkString, pos, "Test string")
    var p = initParser(@[initToken(tkIndent), expected1, initToken(tkNewline), expected2, initToken(tkNewline), initToken(tkDedent)])
    let statements = p.statements()

    check:
      expected1 == statements[0].ExpressionStatement.expression.Atom.value
      expected2 == statements[1].ExpressionStatement.expression.Atom.value

  test "Raises exception when Indent not found":
    var p = initParser(@[fortyTwo, initToken(tkDedent)])

    expect UnexpectedTokenError:
      discard p.statements()

  test "Logs error when EndOfFile instead of Dedent found":
    var p = initParser(@[initToken(tkIndent), fortyTwo, initToken(tkNewline), initToken(tkEndOfFile)])

    let statements = p.statements()

    require:
      1 == len(statements)
      1 == len(p.errors)
    
    check:
      fortyTwo == statements[0].ExpressionStatement.expression.Atom.value

  test "Logs error when Invalid instead of Dedent found":
    var p = initParser(@[initToken(tkIndent), fortyTwo, initToken(tkNewline), initToken(tkInvalid)])

    let statements = p.statements()

    require:
      1 == len(statements)
      1 == len(p.errors)
    
    check:
      fortyTwo == statements[0].ExpressionStatement.expression.Atom.value

suite "Start rule":
  test "Start parses a statement":
    var p = initParser(@[initToken(tkIndent), fortyTwo, initToken(tkNewline), initToken(tkDedent), initToken(tkEndOfFile)])
    let start = p.start()

    check fortyTwo == start.statements[0].ExpressionStatement.expression.Atom.value

  test "Logs error when EndOfFile token not present":
    var p = initParser(@[initToken(tkIndent), fortyTwo, initToken(tkDedent)])
    let tree = p.start()

    require 1 == len(p.errors)
    check:
      fortyTwo == tree.statements[0].ExpressionStatement.expression.Atom.value
