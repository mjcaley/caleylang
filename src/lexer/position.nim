type Position* = object
    l: int
    c: int


proc initPosition*() : Position =
  Position(l: 1, c: 1)

proc initPosition*(line, column: int) : Position =
  Position(l: line, c: column)

proc line*(self: Position) : int =
  self.l

proc column*(self: Position) : int =
  self.c
