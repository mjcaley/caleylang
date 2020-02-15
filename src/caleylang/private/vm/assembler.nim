import lexer, parser

proc assembleString*(data: string) : ParseResults =
  let tokens = lexString(data)
  result = parse(tokens)

when isMainModule:
  let tokens = lexString("""
    .define one i32 1
    .define two i32 2
    
    .func fib: args=1 locals=1
      ldconst one
      ldlocal i32 1
      add i32
  """)
  echo tokens
  var tree = parse(tokens)
  echo tree
