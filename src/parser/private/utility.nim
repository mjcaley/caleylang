import options
import ../../lexer/token

proc match*(self: Option[Token], tokenType: TokenType) : bool =
  self.get(Token(kind: Invalid)).kind == tokenType
