import options
import ../token
import parser_object, parser_utility, parse_tree


type
  ParseResult* = object
    tree*: Start
    errors*: seq[ref ParsingError]


proc tokenOrInvalid(self: Option[Token]) : Token =
  result = self.get(initToken tkInvalid)

proc recoverToNextStatement*(self: var Parser) =
  while not self.current.match(tkNewline, tkEndOfFile, tkDedent):
    discard self.advance()
  discard self.advance()

proc recoverToNextBlock*(self: var Parser) =
  var indents = 0
  while not self.current.match(tkEndOfFile):
    case self.current.tokenOrInvalid.kind:
      of tkEndOfFile:
        break
      of tkIndent:
        inc indents
      of tkDedent:
        if indents == 0:
          break
        dec indents
      else: discard
    discard self.advance()

proc expression*(self: var Parser) : Expression

proc atom*(self: var Parser) : Expression =
  let token = self.current.tokenOrInvalid
  case token.kind:
    of tkDecInteger, tkOctInteger, tkHexInteger, tkBinInteger,
       tkFloat,
       tkTrue, tkFalse,
       tkString,
       tkIdentifier:
      result = newAtom(self.advance().get())
    of tkLeftParen:
      discard self.advance()
      result = self.expression()
      if self.current.match(tkRightParen):
        discard self.advance()
      else:
        raise newException(UnexpectedTokenError, "Found token: " & $self.current.tokenOrInvalid)
    else:
      raise newException(UnexpectedTokenError, "Found token: " & $token)

proc postfixExpression*(self: var Parser) : Expression =
  result = self.atom()

  while self.current.match(tkDot, tkLeftSquare, tkLeftParen):
    let token = self.current.tokenOrInvalid
    case token.kind:
      of tkDot:
        discard self.advance()
        if self.current.match(tkIdentifier):
          result = newFieldAccessExpression(result, self.advance().get())
        else:
          raise newException(UnexpectedTokenError, "Expected an identifier token")
      of tkLeftSquare:
        discard self.advance()
        result = newSubscriptExpression(result, self.expression())
        if self.current.match(tkRightSquare):
          discard self.advance()
        else:
          raise newException(UnexpectedTokenError, "Expected ending right square bracket")
      of tkLeftParen:
        discard self.advance()

        var parameters = newSeq[Expression]()
        while not self.current.match(tkRightParen):
          parameters.add(self.expression())
          if self.current.match(tkComma):
            discard self.advance()
        
        if self.current.match(tkRightParen):
          discard self.advance()
        else:
          raise newException(UnexpectedTokenError, "Expected matching right parentheses token")

        result = newCallExpression(result, parameters)
      else:
        discard

proc unaryExpression*(self: var Parser) : Expression =
  let token = self.current.tokenOrInvalid
  case token.kind:
    of tkNot, tkPlus, tkMinus:
      discard self.advance()
      result = Expression newUnaryExpression(token, self.unaryExpression())
    else:
      result = self.postfixExpression()

proc exponentExpression*(self: var Parser) : Expression =
  result = self.unaryExpression()

  while self.current.match(tkExponent):
    let operator = self.advance().get()
    let right = self.unaryExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc productExpression*(self: var Parser) : Expression =
  result = self.exponentExpression()

  while self.current.match(tkMultiply, tkDivide, tkModulo):
    let operator = self.advance().get()
    let right = self.exponentExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc sumExpression*(self: var Parser) : Expression =
  result = self.productExpression()

  while self.current.match(tkPlus, tkMinus):
    let operator = self.advance().get()
    let right = self.productExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc andExpression*(self: var Parser) : Expression =
  result = self.sumExpression()

  while self.current.match(tkAnd):
    let operator = self.advance().get()
    let right = self.sumExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc orExpression*(self: var Parser) : Expression =
  result = self.andExpression()

  while self.current.match(tkOr):
    let operator = self.advance().get()
    let right = self.andExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc compareExpression*(self: var Parser) : Expression =
  result = self.orExpression()

  while self.current.match(tkEqual, tkNotEqual, tkLessThan, tkLessThanOrEqual, tkGreaterThan, tkGreaterThanOrEqual):
    let operator = self.advance.get()
    let right = self.orExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc assignmentExpression*(self: var Parser) : Expression =
  result = self.compareExpression()

  while self.current.match(tkAssign, tkPlusAssign, tkMinusAssign, tkMultiplyAssign, tkDivideAssign, tkModuloAssign, tkExponentAssign):
    let operator = self.advance.get()
    let right = self.compareExpression()
    let expression = newBinaryExpression(result, right, operator)
    result = expression

proc expression*(self: var Parser) : Expression =
  result = self.assignmentExpression()

proc importStatement*(self: var Parser) : Statement =
  discard self.advance()

  var modules = newSeq[Token]()
  if self.current.match(tkIdentifier):
    modules.add(self.advance().get())
  
  while self.current.match(tkComma) and self.next.match(tkIdentifier):
    discard self.advance()
    modules.add(self.advance().get())
  
  result = newImportStatement(modules)

proc statement*(self: var Parser) : Statement =
  try:
    case self.current.tokenOrInvalid.kind:
      of tkImport:
        result = self.importStatement()
      else:
        result = newExpressionStatement(self.expression())
  except UnexpectedTokenError as e:
    self.logError(e)
    self.recoverToNextStatement()

  case self.current.tokenOrInvalid.kind:
    of tkNewline:
      discard self.advance
    of tkDedent:
      discard
    else:
      raise newException(UnexpectedTokenError, "Expected newline")

proc statements*(self: var Parser) : seq[Statement] =
  if self.current.match(tkIndent):
    discard self.advance()
  else:
    raise newException(UnexpectedTokenError, "Expected indent")

  while true:
    case self.current.tokenOrInvalid.kind:
      of tkDedent:
        discard self.advance()
        break

      of tkInvalid, tkEndOfFile:
        self.logError(newUnexpectedTokenError(
            "Expected dedent at end of statement block",
            self.current.tokenOrInvalid)
        )
        discard self.advance()
        break

      else:
        try:
          result.add(self.statement())
        except UnexpectedTokenError as e:
          self.logError(e)
          self.recoverToNextBlock()
          if self.current.match(tkNewline):
            discard self.advance()

proc start*(self: var Parser) : Start =
  try:
    if not self.current.match(tkEndOfFile):
      result.statements = self.statements()
  except UnexpectedTokenError as e:
    self.logError(e)

  if self.current.match(tkEndOfFile):
    discard self.advance()
  else:
    self.logError(newUnexpectedTokenError("Expected end of file", self.current.tokenOrInvalid))

proc parse*(tokens: seq[Token]) : ParseResult =
  var parser = initParser(tokens)
  let tree = parser.start()
  result = ParseResult(tree: tree, errors: parser.errors)
