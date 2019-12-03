import lexer_stream, options, position, unicode

type
  Context* = object
    stream: LexerStream
    indents: seq[Natural]
    brackets: seq[Rune]
    current: Option[Character]
    next: Option[Character]

proc initContext*(stream: LexerStream) : Context =
  Context(
    stream: stream,
    indents: newSeq[Natural](),
    brackets: newSeq[Rune](),
    current: none(Character),
    next: none(Character)
  )

proc advance*(self: var Context) : Option[Character] =
  self.current = self.next
  self.next = self.stream.next()
  result = self.current

proc pushIndent*(self: var Context, indent: Natural) =
  self.indents.add(indent)

proc popIndent*(self: var Context) : Natural =
  self.indents.pop()

proc lastIndent*(self: Context) : Natural =
  self.indents[self.indents.high]

proc pushBracket*(self: var Context, bracket: Rune) =
  self.brackets.add(bracket)

proc popBracket*(self: var Context) : Rune =
  self.brackets.pop()

proc lastBracket*(self: Context) : Rune =
  self.brackets[self.brackets.high]

proc currentCharacter*(self: Context) : Option[Rune] =
  if self.current.isSome:
    result = some(self.current.get().character)

proc currentPosition*(self: Context) : Option[Position] =
  if self.current.isSome:
    result = some(self.current.get().position)

proc nextCharacter*(self: Context) : Option[Rune] =
  if self.next.isSome:
    result = some(self.next.get().character)

proc nextPosition*(self: Context) : Option[Position] =
  if self.next.isSome:
    result = some(self.next.get().position)
