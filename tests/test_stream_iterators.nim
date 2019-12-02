import stream_iterators, unittest

iterator zip(first, second: iterator(): string) : tuple[first: string, second: string] =
  var first_seq = newSeq[string]()
  for first_item in first:
    first_seq.add(first_item)

test "Characters from string":
  let iter = charactersFromString("Test")

  check:
    iter() == "T"
    iter() == "e"
    iter() == "s"
    iter() == "t"
    finished(iter)
