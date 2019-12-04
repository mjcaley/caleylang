import lexer_stream, options, position, stack, unicode

type
  Context* = object
    stream: LexerStream
    indents*: Stack[Natural]
    brackets*: Stack[Rune]
    current: Option[Character]
    next: Option[Character]

  EmptyStackError* = object of Exception

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
  try:
    self.indents.pop()
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

proc lastIndent*(self: Context) : Natural =
  try:
    self.indents[self.indents.high]
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

proc pushBracket*(self: var Context, bracket: Rune) =
  self.brackets.add(bracket)

proc popBracket*(self: var Context) : Rune =
  try: 
    self.brackets.pop()
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

proc lastBracket*(self: Context) : Rune =
  try:
    self.brackets[self.brackets.high]
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

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
