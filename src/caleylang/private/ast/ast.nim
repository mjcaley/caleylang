import ../parser/parse_tree

type
  Module* = seq[Statement]

  Statement* = ref object of RootObj

  ImportStatement* = ref object of Statement
    modules*: seq[string]
    position*: Position

  ExpressionStatement* = ref object of Statement
    expression*: Expression

  AssignmentStatement* = ref object of Statement
    left*: Expression
    operator*: Token
    right*: Expression

  StructStatement* = ref object of Statement
    members*: seq[Identifier]

  FunctionDecl* = object
    name*: Identifier
    parameters*: seq[Identifier]
    returnType*: Option[Identifier]

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
    right*: Expression
    position*: Position

  AddExpression* = ref object of BinaryExpression

  SubtractExpression* = ref object of BinaryExpression

  MultiplyExpression* = ref object of BinaryExpression

  DivideExpression* = ref object of BinaryExpression

  ModulusExpression* = ref object of BinaryExpression


  UnaryExpression* = ref object of Expression
    operand*: Expression

  NotExpression* = ref object of UnaryExpression

  AndExpression* = ref object of UnaryExpression

  OrExpression* = ref object of UnaryExpression


  CallExpression* = ref object of Expression
    operand*: Expression
    parameters*: seq[Expression]

  FieldAccessExpression* = ref object of Expression
    operand*: Expression
    field*: Identifier
    position*: Position

  SubscriptExpression* = ref object of Expression
    operand*: Expression
    subscript*: Expression

  Atom* = ref object of Expression

  Integer* = ref object of Atom
    value*: int64

  Float* = ref object of Atom
    value*: float64

  String* = ref object of Atom
    value*: string

  Identifier* = ref object of Atom
    value*: string
