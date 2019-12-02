import context, streams, unittest

test "newContext with existing stream":
  let test_input = "Example string"
  let stream = newStringStream(test_input)
  discard initContext(stream)

  check(true)

suite "Context strings":
  test "intContextString with string":
    let test_input = "Example string"
    discard initContextString(test_input)

    check(true)

suite "Context files":
  discard
