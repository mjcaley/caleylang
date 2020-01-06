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
    name*: string
    parameters*: seq[Token]
    returnType: Option[Token]

  FunctionStatement* = ref object of Statement
    decl*: FunctionDecl
    statements*: seq[Statement]


  Expression* = ref object of RootObj

  BinaryExpression* = ref object of Expression
    left*: Expression
    operator*: Token
    right*: Expression

  UnaryExpression* = ref object of Expression
    operator*: Token
    operand*: Expression

  Atom* = ref object of Expression
    value*: Token


  Branch* = ref object
    condition*: Expression
    then*: seq[Statement]
    elseBranch*: Branch


proc newExpressionStatement*(e: Expression) : ExpressionStatement =
  result = new ExpressionStatement
  result.expression = e

proc newAtom*(t: Token) : Atom =
  result = new Atom
  result.value = t

proc newBranch*(condition: Expression, then: seq[Statement], elseBranch: Branch) : Branch =
  result.condition = condition
  result.then = then
  result.elseBranch = elseBranch
