import options
import ../../lexer/token

type
  Parser* = object
    current*: Option[Token]
    next*: Option[Token]
    tokens: iterator() : Token


proc citems(s: seq[Token]) : iterator() : Token =
  result = iterator() : Token =
    for i in s:
      yield i

proc advance*(self: var Parser) =
  self.current = self.next
  let next = self.tokens()
  if self.tokens.finished:
    self.next = none Token
  else:
    self.next = some next

proc initParser*(tokens: seq[Token]) : Parser =
  result = Parser(tokens: citems(tokens))
  result.advance()
  result.advance()
