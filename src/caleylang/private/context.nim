import options
import lexer_stream, ../position, stack
export position.Position

type
  Context* = object
    stream: LexerStream
    indents*: Stack[Natural]
    brackets*: Stack[string]
    currentChar: string
    currentPos: Position
    nextChar: string
    nextPos: Position

  EmptyStackError* = object of Exception


proc initContext*(stream: LexerStream) : Context =
  Context(
    stream: stream,
    indents: newSeq[Natural](),
    brackets: newSeq[string](),
    currentChar: "",
    currentPos: initPosition(line=1, column=0),
    nextChar: "",
    nextPos: initPosition(line=1, column=0)
  )

proc advance*(self: var Context) : string =
  ## Returns character currently in the `current` field.
  ## Replaces `current` with `next` and `next` with the next character in the
  ## stream.

  result = self.currentChar
  self.currentChar = self.nextChar
  self.currentPos = self.nextPos
  let next = self.stream.next()
  if next.isSome:
    self.nextChar = next.get().character
    self.nextPos = next.get().position
  else:
    self.nextChar = ""

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

proc pushBracket*(self: var Context, bracket: string) =
  self.brackets.add(bracket)

proc popBracket*(self: var Context) : string =
  try: 
    self.brackets.pop()
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

proc lastBracket*(self: Context) : string =
  try:
    self.brackets[self.brackets.high]
  except IndexError:
    raise newException(EmptyStackError, "Stack is empty")

proc currentCharacter*(self: Context) : string =
  result = self.currentChar

proc currentPosition*(self: Context) : Position =
  result = self.currentPos

proc nextCharacter*(self: Context) : string =
  result = self.nextChar

proc nextPosition*(self: Context) : Position =
  result = self.nextPos
