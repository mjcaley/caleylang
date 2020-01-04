import options
import ../../lexer/token
import parser_object, parse_tree


proc atom*(self: var Parser) : Atom =
  discard

proc start*(self: var Parser) : Start =
  discard

proc parse*(tokens: seq[Token]) : Start =
  var parser = initParser(tokens)
  parser.start()

when isMainModule:
  let tokens = @[initToken(Indent), initToken(Dedent)]
  var p = initParser(tokens)
  echo p
  let tree = parse(tokens)
  echo tree
