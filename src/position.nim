type Position* = object
    line: Natural
    column: Natural


proc initPosition*() : Position =
    Position()

proc initPosition*(line, column: Natural) : Position =
    Position(line: line, column: column)
