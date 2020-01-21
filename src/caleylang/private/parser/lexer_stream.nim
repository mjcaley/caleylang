import options, streams, unicode
import position
export options, unicode, position

type
  LexerStream* = object
    stream: seq[string]
    index: Natural
    nextPosition: Position

  Character* = tuple[position: Position, character: string]


proc nextCharacter(self: var LexerStream) =
  self.nextPosition = initPosition(line=self.nextPosition.line, column=self.nextPosition.column + 1)

proc nextLine(self: var LexerStream) =
  self.nextPosition = initPosition(line=self.nextPosition.line + 1, column=1)

proc atEnd(self: LexerStream) : bool =
  self.index >= self.stream.len

proc peek(self: LexerStream) : Option[string] =
  let nextIndex = self.index + 1
  if nextIndex < self.stream.len:
    result = some self.stream[nextIndex]

proc current(self: LexerStream) : string =
  self.stream[self.index]

proc advance(self: var LexerStream) : Option[tuple[position: Position, character: string]] =
  if not self.atEnd:
    var character = self.current
    let position = self.nextPosition
    self.index += 1
    if character == "\r":
      character = "\n"
      self.nextLine
      if self.peek().get("") == "\n":
        self.index += 1
    elif character == "\n":
      self.nextLine
    else:
      self.nextCharacter
    result = some (position, character)
  else:
    result = none(Character)

proc toUTF8Seq(input: string) : seq[string] =
  for character in input.utf8:
    result.add(character)

proc initLexerStream(r: seq[string]) : LexerStream =
  result = LexerStream(stream: r, index: 0, nextPosition: initPosition(1, 1))

proc initLexerStreamString*(str: string) : LexerStream =
  initLexerStream(str.toUTF8Seq)

proc initLexerStreamFile*(filename: string) : LexerStream =
  var fstream = openFileStream(filename, fmRead)
  defer: fstream.close()
  let data = fstream.readAll()
  initLexerStream(data.toUTF8Seq)

proc next*(self: var LexerStream) : Option[tuple[position: Position, character: string]] =
  self.advance
