import position
export position

type
  TokenType* = enum
    tkInvalid,

    tkIndent,
    tkDedent,
    
    tkNewline,

    tkDecInteger,
    tkBinInteger,
    tkOctInteger,
    tkHexInteger,
    tkFloat,
    tkString,

    tkIdentifier,

    # Keywords
    tkImport,
    tkFunction,
    tkStruct,
    tkIf,
    tkElseIf,
    tkElse,
    tkWhile,
    tkFor,
    tkAnd,
    tkNot,
    tkOr,
    tkTrue,
    tkFalse,
    tkReturn,

    # Operators
    tkDot,
    tkComma,
    tkColon,

    # Arithmetic
    tkPlus,
    tkMinus,
    tkMultiply,
    tkDivide,
    tkModulo,
    tkExponent,

    # Assignment
    tkAssign,
    tkPlusAssign,
    tkMinusAssign,
    tkMultiplyAssign,
    tkDivideAssign,
    tkModuloAssign,
    tkExponentAssign,

    # Comparision
    tkEqual,
    tkNotEqual,
    tkLessThan,
    tkGreaterThan,
    tkLessThanOrEqual,
    tkGreaterThanOrEqual,

    # Brackets
    tkLeftParen,
    tkRightParen,
    tkLeftBrace,
    tkRightBrace,
    tkLeftSquare,
    tkRightSquare,

    tkError,
    tkEndOfFile

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
