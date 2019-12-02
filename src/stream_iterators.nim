import streams, unicode


proc characters(s: Stream): iterator(): string {.closure.} =
  return iterator(): string =
    for line in s.lines:
      for character in line.utf8:
        yield character

proc charactersFromString*(input: string) : iterator(): string =
  let stream = newStringStream(input)
  characters(stream)

proc charactersFromFilename*(filename: string) : iterator(): string =
  let stream = newFileStream(filename, fmRead)
  characters(stream)
