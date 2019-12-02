import options, position, lexer_stream, unicode, unittest

test "First character from string":
  var stream = initLexerStreamString("Test")
  let result = stream.next()

  if result.isSome:
    let pack = get result
    check:
      pack.position.line == 1
      pack.position.column == 1
      pack.character.toUTF8 == "T"

test "None is returned from empty string":
  var stream = initLexerStreamString("")
  let result = stream.next()
  echo result

  check(result.isNone == true)

test "Characters then none is returned":
  let test_input = "Test"
  var stream = initLexerStreamString(test_input)
  
  var column = 1
  for character in utf8(test_input):
    let result = stream.next()

    require(result.isSome == true)
    let pack = get result

    check:
      pack.position.line == 1
      pack.position.column == column
      pack.character.toUTF8 == character
    inc column

  let result = stream.next()
  check result.isSome == false

test "Newline increases the line position":
  let test_input = "\nTest"
  var stream = initLexerStreamString(test_input)

  discard stream.next()
  let result = stream.next()

  require(result.isSome == true)
  let pack = get result

  check:
    pack.position.line == 2
    pack.position.column == 1
