type Position* = object
    line: int32
    column: int32


proc initPosition*() : Position =
    Position()


proc initPosition*(line, column: int32) : Position =
    Position(line: line, column: column)
