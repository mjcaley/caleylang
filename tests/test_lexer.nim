import unittest
import caleylang/lexer


suite "Indentation states":
  test "Indent and Dedent surround input":
    let results = lexString("")

    check:
      results.len == 3
      results[0].kind == tkIndent
      results[1].kind == tkDedent

  test "Blank lines are ignored":
    let results = lexString(" \n\t\n    \n\t\t\t\t\n")

    check:
      results.len == 3
      results[0].kind == tkIndent
      results[1].kind == tkDedent

  test "Blank line before character is ignored":
    let results = lexString("    \n+")

    check:
      results.len == 4
      results[0].kind == tkIndent
      results[1].kind == tkPlus
      results[2].kind == tkDedent

  test "All remaining dedents are popped":
    let results = lexString("\t+\n\t\t+\n\t\t\t+\n")

    check:
      results.len == 15
      results[10].kind == tkDedent
      results[11].kind == tkDedent
      results[12].kind == tkDedent
      results[13].kind == tkDedent

  test "All remaining brackets are popped as errors":
    let results = lexString("([{")

    check:
      results.len == 9
      results[4].kind == tkError
      results[5].kind == tkError
      results[6].kind == tkError

suite "Operator state":
  test "Newline token":
    let results = lexString("+\n")

    check:
      results.len == 5
      results[2].kind == tkNewline

  test "Dot token":
    let results = lexString(".")

    check:
      results.len == 4
      results[1].kind == tkDot

  test "Comma token":
    let results = lexString(",")

    check:
      results.len == 4
      results[1].kind == tkComma

  test "Colon token":
    let results = lexString(":")

    check:
      results.len == 4
      results[1].kind == tkColon
  
  test "Plus token":
    let results = lexString("+")

    check:
      results.len == 4
      results[1].kind == tkPlus

  test "Minus token":
    let results = lexString("-")

    check:
      results.len == 4
      results[1].kind == tkMinus

  test "Multiply token":
    let results = lexString("*")

    check:
      results.len == 4
      results[1].kind == tkMultiply

  test "Divide token":
    let results = lexString("/")

    check:
      results.len == 4
      results[1].kind == tkDivide

  test "Modulo token":
    let results = lexString("%")

    check:
      results.len == 4
      results[1].kind == tkModulo

  test "Exponent token":
    let results = lexString("**")

    check:
      results.len == 4
      results[1].kind == tkExponent
  
  test "Plus assign token":
    let results = lexString("+=")

    check:
      results.len == 4
      results[1].kind == tkPlusAssign

  test "Minus assign token":
    let results = lexString("-=")

    check:
      results.len == 4
      results[1].kind == tkMinusAssign

  test "Multiply assign token":
    let results = lexString("*=")

    check:
      results.len == 4
      results[1].kind == tkMultiplyAssign

  test "Divide assign token":
    let results = lexString("/=")

    check:
      results.len == 4
      results[1].kind == tkDivideAssign

  test "Modulo assign token":
    let results = lexString("%=")

    check:
      results.len == 4
      results[1].kind == tkModuloAssign

  test "Exponent assign token":
    let results = lexString("**=")

    check:
      results.len == 4
      results[1].kind == tkExponentAssign

  test "Assign token":
    let results = lexString("=")

    check:
      results.len == 4
      results[1].kind == tkAssign

  test "Compare equal token":
    let results = lexString("==")

    check:
      results.len == 4
      results[1].kind == tkEqual

  test "Compare greater than token":
    let results = lexString(">")

    check:
      results.len == 4
      results[1].kind == tkGreaterThan
      
  test "Compare less than token":
    let results = lexString("<")

    check:
      results.len == 4
      results[1].kind == tkLessThan

  test "Compare greater than or equal token":
    let results = lexString(">=")

    check:
      results.len == 4
      results[1].kind == tkGreaterThanOrEqual

  test "Compare less than or equal token":
    let results = lexString("<=")

    check:
      results.len == 4
      results[1].kind == tkLessThanOrEqual

  test "Compare not equal token":
    let results = lexString("!=")

    check:
      results.len == 4
      results[1].kind == tkNotEqual

  test "Open parentheses token":
    let results = lexString("(")

    check:
      results.len == 5
      results[1].kind == tkLeftParen

  test "Open brace token":
    let results = lexString("{")

    check:
      results.len == 5
      results[1].kind == tkLeftBrace

  test "Open square token":
    let results = lexString("[")

    check:
      results.len == 5
      results[1].kind == tkLeftSquare

  test "Close parentheses token":
    let results = lexString("()")

    check:
      results.len == 5
      results[2].kind == tkRightParen

  test "Close brace token":
    let results = lexString("{}")

    check:
      results.len == 5
      results[2].kind == tkRightBrace

  test "Close square token":
    let results = lexString("[]")

    check:
      results.len == 5
      results[2].kind == tkRightSquare

  test "Error parentheses token when not closed":
    let results = lexString("(")

    check:
      results.len == 5
      results[2].kind == tkError

  test "Error brace token when not closed":
    let results = lexString("{")

    check:
      results.len == 5
      results[2].kind == tkError

  test "Error square token when not closed":
    let results = lexString("[")

    check:
      results.len == 5
      results[2].kind == tkError

suite "Word state":
  test "import keyword":
    let results = lexString("import")

    check:
      results.len == 4
      results[1].kind == tkImport

  test "func keyword":
    let results = lexString("func")

    check:
      results.len == 4
      results[1].kind == tkFunction

  test "struct keyword":
    let results = lexString("struct")

    check:
      results.len == 4
      results[1].kind == tkStruct

  test "if keyword":
    let results = lexString("if")

    check:
      results.len == 4
      results[1].kind == tkIf

  test "elif keyword":
    let results = lexString("elif")

    check:
      results.len == 4
      results[1].kind == tkElseIf

  test "else keyword":
    let results = lexString("else")

    check:
      results.len == 4
      results[1].kind == tkElse

  test "while keyword":
    let results = lexString("while")

    check:
      results.len == 4
      results[1].kind == tkWhile

  test "for keyword":
    let results = lexString("for")

    check:
      results.len == 4
      results[1].kind == tkFor

  test "and keyword":
    let results = lexString("and")

    check:
      results.len == 4
      results[1].kind == tkAnd

  test "or keyword":
    let results = lexString("or")

    check:
      results.len == 4
      results[1].kind == tkOr

  test "not keyword":
    let results = lexString("not")

    check:
      results.len == 4
      results[1].kind == tkNot

  test "true keyword":
    let results = lexString("true")

    check:
      results.len == 4
      results[1].kind == tkTrue

  test "false keyword":
    let results = lexString("false")

    check:
      results.len == 4
      results[1].kind == tkFalse

  test "return keyword":
    let results = lexString("return")

    check:
      results.len == 4
      results[1].kind == tkReturn

  test "Identifier starting with a letter":
    let results = lexString("identifier")

    check:
      results.len == 4
      results[1].kind == tkIdentifier
      results[1].value == "identifier"

  test "Identifier starting with an underscore":
    let results = lexString("_identifier")

    check:
      results.len == 4
      results[1].kind == tkIdentifier
      results[1].value == "_identifier"

  test "Identifier as an emoji":
    let results = lexString("😎")

    check:
      results.len == 4
      results[1].kind == tkIdentifier
      results[1].value == "😎"

suite "Number state":
  test "Integer starting with 0 is an error":
    let results = lexString("0123")

    check:
      results.len == 4
      results[1].kind == tkError

  test "Integer with all valid digits":
    let results = lexString("1234567890")

    check:
      results.len == 4
      results[1].kind == tkDecInteger
      results[1].value == "1234567890"

  test "Floating point number, less than 0":
    let results = lexString("0.42")

    check:
      results.len == 4
      results[1].kind == tkFloat
      results[1].value == "0.42"

  test "Floating point number greater than zero":
    let results = lexString("42.42")

    check:
      results.len == 4
      results[1].kind == tkFloat
      results[1].value == "42.42"

  test "Binary integer":
    let results = lexString("0b010101")

    check:
      results.len == 4
      results[1].kind == tkBinInteger
      results[1].value == "0b010101"

  test "Octal integer":
    let results = lexString("0o01234567")

    check:
      results.len == 4
      results[1].kind == tkOctInteger
      results[1].value == "0o01234567"

  test "Hexadecimal integer":
    let results = lexString("0x0123456789abcdef")

    check:
      results.len == 4
      results[1].kind == tkHexInteger
      results[1].value == "0x0123456789abcdef"

suite "Strings state":
  test "Normal string":
    let testInput = "This is a string"
    let results = lexString("\"" & testInput & "\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == testInput

  test "Null escape character":
    let results = lexString("\"\\0\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\0"

  test "Alert escape character":
    let results = lexString("\"\\a\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\a"

  test "Backspace escape character":
    let results = lexString("\"\\b\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\b"

  test "Form feed escape character":
    let results = lexString("\"\\f\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\f"

  test "Newline escape character":
    let results = lexString("\"\\n\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\n"

  test "Carriage return escape character":
    let results = lexString("\"\\r\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\r"

  test "Horizontal tab escape character":
    let results = lexString("\"\\t\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\t"

  test "Vertical tab escape character":
    let results = lexString("\"\\v\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\v"

  test "Backslash escape character":
    let results = lexString("\"" & "\\\\" & "\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\\"

  test "Double quote escape character":
    let results = lexString("\"" & "\\\"" & "\"")

    check:
      results.len == 4
      results[1].kind == tkString
      results[1].value == "\""

  test "Invalid escape character is an error":
    let results = lexString("\"\\y\"")

    check:
      results[1].kind == tkError

  test "String without ending double quote is an error":
    let results = lexString("\"This is an incomplete string")

    check:
      results[1].kind == tkError

  test "String with newline in the middle is an error":
    let results = lexString("\"There shouldn't be a newline here\n")

    check:
      results[1].kind == tkError
