type
  Stack*[T] = seq[T]


proc top*[T](s: Stack[T]) : T =
  result = s[s.high]

proc empty*[T](s: Stack[T]) : bool =
  result = s.len == 0

proc push*[T](s: var Stack[T], value: T) =
  s.add(value)
