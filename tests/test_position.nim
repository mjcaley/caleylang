import unittest
import caleylang/position


test "Position defaults to line 1, column 1":
  let position = initPosition()

  check:
    position.line == 1
    position.column == 1

test "Position with custom line and column":
  let position = initPosition(line=4, column=2)

  check:
    position.line == 4
    position.column == 2
