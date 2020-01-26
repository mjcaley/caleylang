import lexer, parser

proc assembleString*(data: string) : ParseResults =
  let tokens = lexString(data)
  result = parse(tokens)
