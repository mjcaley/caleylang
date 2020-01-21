import private/parser/[lexer, parser]
export Token, Position, parser.position.line, parser.position.column
export ParseResult
export parser.parse_tree
export UnexpectedTokenError


proc parseFile*(filename: string) : ParseResult =
  let tokens = lexFile(filename)
  result = parse(tokens)

proc parseString*(input: string) : ParseResult =
  let tokens = lexString(input)
  result = parse(tokens)
