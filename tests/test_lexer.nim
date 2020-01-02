import unittest
import lexer/lexer


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

test "Newline token":
  let results = lexString("+\n")

  check:
    results.len == 4
    results[2].kind == Newline
