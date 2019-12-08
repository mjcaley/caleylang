import private / [context, lexer_object, lexer_stream, states], position, token
export Position, position.line, position.column
export Token, TokenType
export Lexer, initLexerFromFile, initLexerFromString
export emit
