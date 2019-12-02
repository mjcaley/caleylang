type Position* = object
    l: Natural
    c: Natural


proc initPosition*() : Position =
  Position(l: 1, c: 1)

proc initPosition*(line, column: Natural) : Position =
  Position(l: line, c: column)

proc line*(self: Position) : Natural =
  self.l

proc column*(self: Position) : Natural =
  self.c
