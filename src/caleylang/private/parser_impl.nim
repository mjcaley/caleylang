import options
import ../token
import parser_object, parse_tree


type
  ParsingError* = object of Exception
  UnexpectedTokenError* = object of ParsingError


proc atom*(self: var Parser) : Atom =
  let token = self.current.get(initToken Invalid)
  case token.kind:
    of DecInteger, OctInteger, HexInteger, BinInteger,
       Float,
       True, False,
       String,
       Identifier:
      result = newAtom(self.advance().get())
    else:
      raise newException(UnexpectedTokenError, "Found token: " & $token)

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
