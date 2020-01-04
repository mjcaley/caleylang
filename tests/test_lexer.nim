import unittest
import caleylang/lexer


suite "Indentation states":
  test "Indent and Dedent surround input":
    let results = lexString("")

    check:
      results.len == 2
      results[0].kind == Indent
      results[1].kind == Dedent

  test "Blank lines are ignored":
    let results = lexString(" \n\t\n    \n\t\t\t\t\n")

    check:
      results.len == 2
      results[0].kind == Indent
      results[1].kind == Dedent

  test "Blank line before character is ignored":
    let results = lexString("    \n+")

    check:
      results.len == 3
      results[0].kind == Indent
      results[1].kind == Plus
      results[2].kind == Dedent

  test "All remaining dedents are popped":
    let results = lexString("\t+\n\t\t+\n\t\t\t+\n")

    check:
      results.len == 14
      results[10].kind == Dedent
      results[11].kind == Dedent
      results[12].kind == Dedent
      results[13].kind == Dedent

  test "All remaining brackets are popped as errors":
    let results = lexString("([{")

    check:
      results.len == 8
      results[4].kind == Error
      results[5].kind == Error
      results[6].kind == Error

suite "Operator state":
  test "Newline token":
    let results = lexString("+\n")

    check:
      results.len == 4
      results[2].kind == Newline

  test "Dot token":
    let results = lexString(".")

    check:
      results.len == 3
      results[1].kind == Dot

  test "Comma token":
    let results = lexString(",")

    check:
      results.len == 3
      results[1].kind == Comma

  test "Colon token":
    let results = lexString(":")

    check:
      results.len == 3
      results[1].kind == Colon
  
  test "Plus token":
    let results = lexString("+")

    check:
      results.len == 3
      results[1].kind == Plus

  test "Minus token":
    let results = lexString("-")

    check:
      results.len == 3
      results[1].kind == Minus

  test "Multiply token":
    let results = lexString("*")

    check:
      results.len == 3
      results[1].kind == Multiply

  test "Divide token":
    let results = lexString("/")

    check:
      results.len == 3
      results[1].kind == Divide

  test "Modulo token":
    let results = lexString("%")

    check:
      results.len == 3
      results[1].kind == Modulo

  test "Exponent token":
    let results = lexString("**")

    check:
      results.len == 3
      results[1].kind == Exponent
  
  test "Plus assign token":
    let results = lexString("+=")

    check:
      results.len == 3
      results[1].kind == PlusAssign

  test "Minus assign token":
    let results = lexString("-=")

    check:
      results.len == 3
      results[1].kind == MinusAssign

  test "Multiply assign token":
    let results = lexString("*=")

    check:
      results.len == 3
      results[1].kind == MultiplyAssign

  test "Divide assign token":
    let results = lexString("/=")

    check:
      results.len == 3
      results[1].kind == DivideAssign

  test "Modulo assign token":
    let results = lexString("%=")

    check:
      results.len == 3
      results[1].kind == ModuloAssign

  test "Exponent assign token":
    let results = lexString("**=")

    check:
      results.len == 3
      results[1].kind == ExponentAssign

  test "Assign token":
    let results = lexString("=")

    check:
      results.len == 3
      results[1].kind == Assign

  test "Compare equal token":
    let results = lexString("==")

    check:
      results.len == 3
      results[1].kind == Equal

  test "Compare greater than token":
    let results = lexString(">")

    check:
      results.len == 3
      results[1].kind == GreaterThan
      
  test "Compare less than token":
    let results = lexString("<")

    check:
      results.len == 3
      results[1].kind == LessThan

  test "Compare greater than or equal token":
    let results = lexString(">=")

    check:
      results.len == 3
      results[1].kind == GreaterThanOrEqual

  test "Compare less than or equal token":
    let results = lexString("<=")

    check:
      results.len == 3
      results[1].kind == LessThanOrEqual

  test "Compare not equal token":
    let results = lexString("!=")

    check:
      results.len == 3
      results[1].kind == NotEqual

  test "Open parentheses token":
    let results = lexString("(")

    check:
      results.len == 4
      results[1].kind == LeftParen

  test "Open brace token":
    let results = lexString("{")

    check:
      results.len == 4
      results[1].kind == LeftBrace

  test "Open square token":
    let results = lexString("[")

    check:
      results.len == 4
      results[1].kind == LeftSquare

  test "Close parentheses token":
    let results = lexString("()")

    check:
      results.len == 4
      results[2].kind == RightParen

  test "Close brace token":
    let results = lexString("{}")

    check:
      results.len == 4
      results[2].kind == RightBrace

  test "Close square token":
    let results = lexString("[]")

    check:
      results.len == 4
      results[2].kind == RightSquare

  test "Error parentheses token when not closed":
    let results = lexString("(")

    check:
      results.len == 4
      results[2].kind == Error

  test "Error brace token when not closed":
    let results = lexString("{")

    check:
      results.len == 4
      results[2].kind == Error

  test "Error square token when not closed":
    let results = lexString("[")

    check:
      results.len == 4
      results[2].kind == Error

  test "Operator state errors on unrecognized token":
    let results = lexString("")

    check:
      true

suite "Word state":
  test "import keyword":
    let results = lexString("import")

    check:
      results.len == 3
      results[1].kind == Import

  test "func keyword":
    let results = lexString("func")

    check:
      results.len == 3
      results[1].kind == Function

  test "struct keyword":
    let results = lexString("struct")

    check:
      results.len == 3
      results[1].kind == Struct

  test "if keyword":
    let results = lexString("if")

    check:
      results.len == 3
      results[1].kind == If

  test "elif keyword":
    let results = lexString("elif")

    check:
      results.len == 3
      results[1].kind == ElseIf

  test "else keyword":
    let results = lexString("else")

    check:
      results.len == 3
      results[1].kind == Else

  test "while keyword":
    let results = lexString("while")

    check:
      results.len == 3
      results[1].kind == While

  test "for keyword":
    let results = lexString("for")

    check:
      results.len == 3
      results[1].kind == For

  test "and keyword":
    let results = lexString("and")

    check:
      results.len == 3
      results[1].kind == And

  test "or keyword":
    let results = lexString("or")

    check:
      results.len == 3
      results[1].kind == Or

  test "not keyword":
    let results = lexString("not")

    check:
      results.len == 3
      results[1].kind == Not

  test "true keyword":
    let results = lexString("true")

    check:
      results.len == 3
      results[1].kind == True

  test "false keyword":
    let results = lexString("false")

    check:
      results.len == 3
      results[1].kind == False

  test "return keyword":
    let results = lexString("return")

    check:
      results.len == 3
      results[1].kind == Return

  test "Identifier starting with a letter":
    let results = lexString("identifier")

    check:
      results.len == 3
      results[1].kind == Identifier
      results[1].value == "identifier"

  test "Identifier starting with an underscore":
    let results = lexString("_identifier")

    check:
      results.len == 3
      results[1].kind == Identifier
      results[1].value == "_identifier"

  test "Identifier as an emoji":
    let results = lexString("😎")

    check:
      results.len == 3
      results[1].kind == Identifier
      results[1].value == "😎"

suite "Number state":
  test "Integer starting with 0 is an error":
    let results = lexString("0123")

    check:
      results[1].kind == Error

  test "Integer with all valid digits":
    let results = lexString("1234567890")

    check:
      results.len == 3
      results[1].kind == DecInteger
      results[1].value == "1234567890"

  test "Floating point number, less than 0":
    let results = lexString("0.42")

    check:
      results.len == 3
      results[1].kind == Float
      results[1].value == "0.42"

  test "Floating point number greater than zero":
    let results = lexString("42.42")

    check:
      results.len == 3
      results[1].kind == Float
      results[1].value == "42.42"

  test "Binary integer":
    let results = lexString("0b010101")

    check:
      results.len == 3
      results[1].kind == BinInteger
      results[1].value == "0b010101"

  test "Octal integer":
    let results = lexString("0o01234567")

    check:
      results.len == 3
      results[1].kind == OctInteger
      results[1].value == "0o01234567"

  test "Hexadecimal integer":
    let results = lexString("0x0123456789abcdef")

    check:
      results.len == 3
      results[1].kind == HexInteger
      results[1].value == "0x0123456789abcdef"

suite "Strings state":
  test "Normal string":
    let testInput = "This is a string"
    let results = lexString("\"" & testInput & "\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == testInput

  test "Null escape character":
    let results = lexString("\"\\0\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\0"

  test "Alert escape character":
    let results = lexString("\"\\a\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\a"

  test "Backspace escape character":
    let results = lexString("\"\\b\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\b"

  test "Form feed escape character":
    let results = lexString("\"\\f\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\f"

  test "Newline escape character":
    let results = lexString("\"\\n\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\n"

  test "Carriage return escape character":
    let results = lexString("\"\\r\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\r"

  test "Horizontal tab escape character":
    let results = lexString("\"\\t\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\t"

  test "Vertical tab escape character":
    let results = lexString("\"\\v\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\v"

  test "Backslash escape character":
    let results = lexString("\"" & "\\\\" & "\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\\"

  test "Double quote escape character":
    let results = lexString("\"" & "\\\"" & "\"")

    check:
      results.len == 3
      results[1].kind == String
      results[1].value == "\""

  test "Invalid escape character is an error":
    let results = lexString("\"\\y\"")

    check:
      results[1].kind == Error

  test "String without ending double quote is an error":
    let results = lexString("\"This is an incomplete string")

    check:
      results[1].kind == Error

  test "String with newline in the middle is an error":
    let results = lexString("\"There shouldn't be a newline here\n")

    check:
      results[1].kind == Error
