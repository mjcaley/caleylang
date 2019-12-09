import options, unicode, unittest
import lexer/private/lexer_stream, lexer/position


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

test "Advances through string":
  let test_input = "Test"
  var stream = initLexerStreamString(test_input)
  let default = (position: initPosition(), character: "\0".runeAt(0))

  check:
    "T".runeAt(0) == stream.next().get(default).character
    "e".runeAt(0) == stream.next().get(default).character
    "s".runeAt(0) == stream.next().get(default).character
    "t".runeAt(0) == stream.next().get(default).character

test "Position increments on line":
  let test_input = "Test"
  var stream = initLexerStreamString(test_input)
  let default = (position: initPosition(), character: "\0".runeAt(0))

  check:
    initPosition(line=1, column=1) == stream.next().get(default).position
    initPosition(line=1, column=2) == stream.next().get(default).position
    initPosition(line=1, column=3) == stream.next().get(default).position
    initPosition(line=1, column=4) == stream.next().get(default).position
