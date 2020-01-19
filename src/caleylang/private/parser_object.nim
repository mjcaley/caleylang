import options
import ../token

type
  Parser* = object
    current*: Option[Token]
    next*: Option[Token]
    tokens: iterator() : Token
    errors*: seq[ref ParsingError]
    
  ParsingError* = object of Exception
    token: Token
  
  UnexpectedTokenError* = object of ParsingError


proc citems(s: seq[Token]) : iterator() : Token =
  result = iterator() : Token =
    for i in s:
      yield i

proc advance*(self: var Parser) : Option[Token] =
  result = self.current
  self.current = self.next
  let next = self.tokens()
  if self.tokens.finished:
    self.next = none Token
  else:
    self.next = some next

# proc logError*(self: var Parser, error: ref ParsingError, token: Token) =
#   self.errors.add (error, token)

template logError*(self: var Parser, exception: ref ParsingError) =
  self.errors.add(exception)

proc newUnexpectedTokenError*(message: string, token: Token) : ref UnexpectedTokenError =
  result = newException(UnexpectedTokenError, message)
  result.token = token

proc initParser*(tokens: seq[Token]) : Parser =
  result = Parser(tokens: citems(tokens), errors: @[])
  discard result.advance()
  discard result.advance()
