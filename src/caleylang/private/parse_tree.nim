import options
import ../token


type
  Start* = object
    statements*: seq[Statement]


  Statement* = ref object of RootObj

  ImportStatement* = ref object of Statement
    modules*: seq[Token]

  ExpressionStatement* = ref object of Statement
    expression*: Expression

  AssignmentStatement* = ref object of Statement
    left*: Expression
    operator*: Token
    right*: Expression

  StructStatement* = ref object of Statement
    members*: seq[Token]

  FunctionDecl* = object
    name*: Token
    parameters*: seq[Token]
    returnType*: Option[Token]

  FunctionStatement* = ref object of Statement
    decl*: FunctionDecl
    statements*: seq[Statement]

  BranchStatement* = ref object of Statement
    condition*: Expression
    then*: seq[Statement]
    elseBranch*: BranchStatement


  Expression* = ref object of RootObj

  BinaryExpression* = ref object of Expression
    left*: Expression
    operator*: Token
    right*: Expression

  UnaryExpression* = ref object of Expression
    operator*: Token
    operand*: Expression

  CallExpression* = ref object of Expression
    operand*: Expression
    parameters*: seq[Expression]

  FieldAccessExpression* = ref object of Expression
    operand*: Expression
    field*: Token

  SubscriptExpression* = ref object of Expression
    operand*: Expression
    subscript*: Expression

  Atom* = ref object of Expression
    value*: Token


proc newImportStatement*(modules: seq[Token]) : ImportStatement =
  result = new ImportStatement
  result.modules = modules

proc newExpressionStatement*(e: Expression) : ExpressionStatement =
  result = new ExpressionStatement
  result.expression = e

proc newBranchStatement*(condition: Expression, then: seq[Statement], elseBranch: BranchStatement) : BranchStatement =
  result.condition = condition
  result.then = then
  result.elseBranch = elseBranch
  

proc newUnaryExpression*(operator: Token, operand: Expression) : UnaryExpression =
  result = new UnaryExpression
  result.operator = operator
  result.operand = operand

proc newBinaryExpression*(left, right: Expression, operator: Token) : BinaryExpression =
  result = new BinaryExpression
  result.left = left
  result.right = right
  result.operator = operator

proc newCallExpression*(operand: Expression, parameters: seq[Expression]) : CallExpression =
  result = new CallExpression
  result.operand = operand
  result.parameters = parameters

proc newFieldAccessExpression*(operand: Expression, field: Token) : FieldAccessExpression =
  result = new FieldAccessExpression
  result.operand = operand
  result.field = field

proc newSubscriptExpression*(operand, subscript: Expression) : SubscriptExpression =
  result = new SubscriptExpression
  result.operand = operand
  result.subscript = subscript

proc newAtom*(t: Token) : Atom =
  result = new Atom
  result.value = t