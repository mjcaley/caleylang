import token, streams, unicode

# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

let example = "ϷThis is an example string"

proc byRune(s: Stream): iterator(): string =
  return iterator(): string =
    for line in s.lines:
      for character in line.utf8:
        yield character

proc main() =
  echo("Hello, World!")
  let tok = initToken(Indent, 1, 1)

  var buffer: string
  var stream = newStringStream(example)
  var iter = byRune(stream)
  for i in 1..5:
    let next = iter()
    echo next

when isMainModule:
  
  let something = 42
  echo something
  main()
