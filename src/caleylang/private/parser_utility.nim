import options
import ../token


proc match*(self: Option[Token], tokenTypes: varargs[TokenType]) : bool =
  let token = self.get(Token(kind: tkInvalid)).kind

  for tokenType in tokenTypes:
    if tokenType == token:
      result = true
      break
