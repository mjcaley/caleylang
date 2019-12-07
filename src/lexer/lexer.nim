import private / [context, lexer_object, lexer_stream, states], position, token
export position.Position
export token.Token, token.TokenType
export lexer_object.Lexer, lexer_object.initLexerStreamFile, lexer_object.initLexerStreamString
export states.emit
