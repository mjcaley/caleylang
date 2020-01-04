import options
import ../../lexer/token


type
  Start* = object
    statements*: Statements


  Statement* = object of RootObj

  Statements* = seq[Statement]

  ImportStatement* = object of Statement
    modules*: seq[Token]

  ExpressionStatement* = object of Statement
    expression*: Expression

  AssignmentStatement* = object of Statement
    left*: Expression
    operator*: Token
    right*: Expression

  StructStatement* = object of Statement
    members*: seq[Token]

  FunctionDecl* = object
    name*: string
    parameters*: seq[Token]
    returnType: Option[Token]

  FunctionStatement* = object of Statement
    decl*: FunctionDecl
    statements*: Statements


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
    then*: Statements
    elseBranch*: Branch
