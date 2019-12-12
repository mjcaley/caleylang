import lexer_object, context, constants
export lexer_object.Lexer


proc current*(self: Lexer) : string =
  result = self.context.currentCharacter
  
proc next*(self: Lexer) : string =
  result = self.context.nextCharacter

proc match*(self: Lexer, character: string) : bool =
  result = self.current == character

proc matchAny*(self: Lexer, characters: openArray[string]) : bool =
  for character in characters:
    if self.match(character):
      return true

proc matchNext*(self: Lexer, character: string) : bool =
  result = self.next == character

proc lexemeWhile*[T](self: var Lexer, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.context.advance())
  self.lexeme = result

proc appendWhile*[T](self: var Lexer, characters: openArray[T]) : string =
  while self.matchAny(characters):
    result.add(self.context.advance())

proc appendWhileNot*[T](self: var Lexer, characters: openArray[T]) : string =
  while not self.matchAny(characters):
    result.add(self.current)
    discard self.context.advance()

proc skip*[T](self: var Lexer, character: T) =
  when T is seq or T is array:
    while self.matchAny(character):
      discard self.context.advance()
  else:
    while self.match(character):
      discard self.context.advance()

proc skipWhitespace*(self: var Lexer) =
  self.skip(WhitespaceChars)

proc eof*(self: Lexer) : bool =
  self.current == "" and self.next == ""

proc consume*(self: var Lexer) : string =
  result = self.lexeme
  self.lexeme = ""
  