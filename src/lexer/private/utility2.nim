import lexer_object, context, constants


proc current*(self: var Context) : string =
  result = self.currentCharacter
  
proc next*(self: var Context) : string =
  result = self.nextCharacter

proc match*(self: var Context, character: string) : bool =
  result = self.current == character

proc matchAny*(self: var Context, characters: openArray[string]) : bool =
  for character in characters:
    if self.match(character):
      return true

proc matchNext*(self: var Context, character: string) : bool =
  result = self.next == character

proc matchNextAny*(self: var Context, characters: openArray[string]) : bool =
  for character in characters:
    if self.matchNext(character):
      return true

proc lexemeWhile*[T](self: var Context, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.advance())
  self.lexeme = result

proc appendWhile*[T](self: var Context, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.advance())

proc appendWhileNot*[T](self: var Context, characters: openArray[T]) : string =
  while not self.matchAny(characters) and self.currentCharacter != "":
    result.add(self.current)
    discard self.advance()

proc skip*[T](self: var Context, character: T) =
  when T is seq or T is array:
    while self.matchAny(character):
      discard self.advance()
  else:
    while self.match(character):
      discard self.advance()

proc skipWhitespace*(self: var Context) =
  self.skip(WhitespaceChars)

proc eof*(self: var Context) : bool =
  self.current == "" and self.next == ""
