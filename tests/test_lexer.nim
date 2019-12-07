import unittest
import lexer/lexer


test "Default Start state":
  var l = initLexerFromString("")

  check l.state == State.Start

# test "All Dedents are popped":
#   var l = initLexerFromString("    +\n        +\n")
#   echo "State:", l.state, " Token: ", l.emit().kind
#   echo "State:", l.state, " Token: ", l.emit().kind
#   echo "State:", l.state, " Token: ", l.emit().kind
#   echo "State:", l.state, " Token: ", l.emit().kind
#   echo "State:", l.state, " Token: ", l.emit().kind
#   echo "State:", l.state, " Token: ", l.emit().kind
#   # discard l.emit()
#   # discard l.emit()
#   # discard l.emit()
#   # discard l.emit()
#   # discard l.emit()
#   # discard l.emit()
#   # discard l.emit()

#   check:
#     l.emit().kind == Dedent
#     l.emit().kind == Dedent
#     l.emit().kind == EndOfFile

# test "EndOfFile token on end state":
#   var l = initLexerFromString("")
#   let result = l.emit()

#   check result.kind == EndOfFile

# test "Indent on whitespace":
#   var l = initLexerFromString("    42")
#   let result = l.emit()

#   check result.kind == Indent

# test "Don't return Indent on blank line":
#   var l = initLexerFromString("    \n42")
#   let result = l.emit()

#   check result.kind != Indent

# test "Return integer":
#   let test_input = "42"
#   var l = initLexerFromString(test_input)
#   let result = l.emit()

#   check:
#     result.kind == Integer
#     result.value == test_input

# test "Count":
#   let test_input = "+++++"
#   var l = initLexerFromString(test_input)
#   echo l.emit()
#   echo l.emit()
#   echo l.emit()
#   echo l.emit()
#   echo l.emit()
