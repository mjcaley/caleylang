import position

type
  TokenType* = enum
    Indent,
    Dedent,
    
    Newline,

    Integer,
    Float,
    String,

    Identifier,

    # Keywords
    Function,
    Struct,
    If,
    ElseIf,
    Else,
    While,
    For,
    And,
    Not,
    Or,
    True,
    False,
    Return,

    # Operators
    Dot,
    Comma,
    Colon,

    # Arithmetic
    Plus,
    Minus,
    Multiply,
    Divide,
    Modulo,
    Exponent,

    # Assignment
    Assign,
    PlusAssign,
    MinusAssign,
    MultiplyAssign,
    DivideAssign,
    ModuloAssign,
    ExponentAssign,

    # Comparision
    Equal,
    NotEqual,
    LessThan,
    GreaterThan,
    LessThanOrEqual,
    GreaterThanOrEqual,

    # Brackets
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    LeftSquare,
    RightSquare,

    Error

  Token* = object
    kind*: TokenType
    pos*: Position
    value*: string


proc initToken*(kind: TokenType, pos: Position, value: string) : Token =
  Token(kind: kind, pos: pos, value: value)

proc initToken*(kind: TokenType, pos: Position) : Token =
  initToken(kind, pos, "")

proc initToken*(kind: TokenType, line, column: int32, value: string) : Token =
  initToken(kind, initPosition(line, column), value)

proc initToken*(kind: TokenType, line, column: int32) : Token =
  initToken(kind, line, column, "")
