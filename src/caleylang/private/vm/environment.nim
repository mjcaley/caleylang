import value, frame

type
  Environment* = object
    ip*: Natural
    program*: seq[byte]
    operandStack*: seq[Value]
    callStack*: seq[Frame]
    constants*: seq[Constant]

  VMRuntimeError* = object of Exception
