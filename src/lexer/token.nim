import position

type
  TokenType* = enum
    Indent,
    Dedent,
    
    Newline,

    DecInteger,
    BinInteger,
    OctInteger,
    HexInteger,
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

    Error,
    EndOfFile

  Token* = object
    kind*: TokenType
    position*: Position
    value*: string


proc initToken*(kind: TokenType, position: Position, value: string) : Token =
  Token(kind: kind, position: position, value: value)

proc initToken*(kind: TokenType, position: Position) : Token =
  initToken(kind, position, "")

proc initToken*(kind: TokenType, line, column: int32, value: string) : Token =
  initToken(kind, initPosition(line, column), value)

proc initToken*(kind: TokenType, line, column: int32) : Token =
  initToken(kind, line, column, "")

proc initToken*(kind: TokenType) : Token =
  initToken(kind, 0, 0)
