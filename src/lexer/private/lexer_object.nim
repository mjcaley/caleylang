import context, lexer_stream

type
    State* {.pure.} = enum
      Start,
      IsEOF,
      Indent,
      Dedent,
      Operator,
      Number,
      String,
      Word,
      End
  
    Lexer* = object
      state: State
      context*: Context
      lexeme: string


proc initLexerFromString*(str: string) : Lexer =
  var stream = initLexerStreamString(str)
  Lexer(context: initContext(stream), state: State.Start)

proc initLexerFromFile*(filename: string) : Lexer =
  var stream = initLexerStreamFile(filename)
  Lexer(context: initContext(stream), state: State.Start)      

proc state*(self: Lexer) : State =
  self.state

proc `state=`*(self: var Lexer, value: State) =
  self.state = value

proc context*(self: var Lexer) : var Context =
  self.context

proc lexeme*(self: Lexer) : string =
  self.lexeme

proc `lexeme=`*(self: var Lexer, value: string) =
  self.lexeme = value
