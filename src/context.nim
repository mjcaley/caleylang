import streams, unicode


type
  Context* = ref object
    stream: Stream
    iter: iterator(): string


proc characters(s: Stream): iterator(): string =
  return iterator(): string =
    for line in s.lines:
      for character in line.utf8:
        yield character

proc initContext*(stream: Stream) : Context =
  Context(stream: stream, iter: characters(stream))

proc initContextString*(input: string) : Context =
  let stream = newStringStream(input)
  initContext(stream)

proc initContextFile*(filename: string) : Context =
  let file = newFileStream(filename, fmRead)
  initContext(file)
