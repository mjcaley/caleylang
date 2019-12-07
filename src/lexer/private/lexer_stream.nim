import options, streams, unicode
import ../position
export position.Position

type
  LexerStream* = object
    stream: Stream
    buffer: seq[Rune]
    nextPosition: Position

  Character* = tuple[position: Position, character: Rune]


proc bufferIndex(self: LexerStream) : Natural =
  self.nextPosition.column - 1

proc endOfBuffer(self: LexerStream) : bool =
  self.bufferIndex >= self.buffer.len

proc updateBuffer(self: var LexerStream) =
  if not self.stream.atEnd:
    var line = ""
    discard self.stream.readLine(line)
    self.buffer = line.toRunes
  
proc nextCharacter(self: var LexerStream) =
  self.nextPosition = initPosition(self.nextPosition.line, self.nextPosition.column + 1)

proc nextLine(self: var LexerStream) =
  self.updateBuffer
  self.nextPosition = initPosition(self.nextPosition.line + 1, 1)

const newline = "\n".runeAt(0)

proc advance(self: var LexerStream) : Option[tuple[position: Position, character: Rune]] =
  if not self.endOfBuffer:
    let character = self.buffer[self.bufferIndex]
    result = some((self.nextPosition, character))
    self.nextCharacter
  elif not self.stream.atEnd:
    result = some((self.nextPosition, newline))
    self.nextLine
  else:
    result = none(Character)
    self.stream.close()

proc initLexerStream(s: Stream) : LexerStream =
  result = LexerStream(stream: s, buffer: newSeq[Rune](), nextPosition: initPosition(0, 0))
  result.nextLine()

proc initLexerStreamString*(str: string) : LexerStream =
  initLexerStream(newStringStream(str))

proc initLexerStreamFile*(filename: string) : LexerStream =
  initLexerStream(openFileStream(filename, fmRead))

proc next*(self: var LexerStream) : Option[tuple[position: Position, character: Rune]] =
  self.advance
