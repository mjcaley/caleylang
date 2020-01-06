import options
import ../token
import parser_object, parser_utility, parse_tree


type
  ParsingError* = object of Exception
  UnexpectedTokenError* = object of ParsingError


proc tokenOrInvalid(self: Option[Token]) : Token =
  result = self.get(initToken Invalid)

proc expression*(self: var Parser) : Expression

proc atom*(self: var Parser) : Expression =
  let token = self.current.tokenOrInvalid
  case token.kind:
    of DecInteger, OctInteger, HexInteger, BinInteger,
       Float,
       True, False,
       String,
       Identifier:
      result = newAtom(self.advance().get())
    of LeftParen:
      discard self.advance()
      result = self.expression()
      if self.current.match(RightParen):
        discard self.advance()
      else:
        raise newException(UnexpectedTokenError, "Found token: " & $self.current.tokenOrInvalid)
    else:
      raise newException(UnexpectedTokenError, "Found token: " & $token)

proc unaryExpression*(self: var Parser) : Expression =
  let token = self.current.tokenOrInvalid
  case token.kind:
    of Not, Plus, Minus:
      discard self.advance()
      result = Expression newUnaryExpression(token, self.expression())
    else:
      result = self.atom()

proc expression*(self: var Parser) : Expression =
  result = self.atom()

proc statement*(self: var Parser) : Statement =
  result = Statement newExpressionStatement(self.expression())

proc statements*(self: var Parser) : seq[Statement] =
  while self.current.get(initToken(EndOfFile)).kind != EndOfFile:
    result.add(self.statement)

proc start*(self: var Parser) : Start =
  result.statements = self.statements()

proc parse*(tokens: seq[Token]) : Start =
  var parser = initParser(tokens)
  parser.start()
