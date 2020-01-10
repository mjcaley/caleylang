import options
import private/parse_tree, token, parser, lexer

type
  PrinterState = object
    nodeChildren: seq[int]


const Empty = "    "
const Trunk = "  \u2502 "
const LastChild = "  \u2514\u2500"
const ChildBranch = "  \u251c\u2500"


proc initPrinterState() : PrinterState =
  PrinterState(nodeChildren: @[])

proc push(self: var PrinterState, children: int = 0) =
  self.nodeChildren.add(children)

proc pop(self: var PrinterState) =
  discard self.nodeChildren.pop()

proc decChildren(self: var PrinterState) =
  if len(self.nodeChildren) == 0:
    return

  dec self.nodeChildren[high self.nodeChildren]

proc generateHeader(self: PrinterState) : string =
  if len(self.nodeChildren) == 0:
    return

  let lastChild = high(self.nodeChildren) - 1
  for children in self.nodeChildren[0..lastChild]:
    case children:
      of 0:
        result &= Empty
      else:
        result &= Trunk
  
  case self.nodeChildren[high(self.nodeChildren)]:
    of 0:
      result &= Empty
    of 1:
      result &= LastChild
    else:
      result &= ChildBranch

proc printMe(p: var PrinterState, name: string)
proc printChild[T](p: var PrinterState, child: T)

proc print(s: Start, p: var PrinterState) =
  p.printMe "Start"
  p.push s.statements.len
  for node in s.statements:
    p.printChild(node)
  p.pop

# Statements
method print(s: Statement, p: var PrinterState) {.base.} =
  p.printMe "Statement"

method print(i: ImportStatement, p: var PrinterState) =
  p.printMe "ImportStatement"
  p.push i.modules.len

  p.pop

method print(e: ExpressionStatement, p: var PrinterState) =
  p.printMe "ExpressionStatement"
  p.push 1
  p.printChild(e.expression)
  p.pop

method print(a: AssignmentStatement, p: var PrinterState) =
  p.printMe "AssignmentStatement"
  p.push 3
  p.printChild(a.left)
  p.printChild(a.operator)
  p.printChild(a.right)
  p.pop

method print(s: StructStatement, p: var PrinterState) =
  p.printMe "StructStatement"
  p.push s.members.len
  for child in s.members:
    p.printChild(child)
  p.pop

method print(f: FunctionStatement, p: var PrinterState) =
  p.printMe "FunctionStatement"
  p.push 1 + f.statements.len
  p.printChild(f.decl)
  for statement in f.statements:
    p.printChild(statement)
  p.pop

method print(b: BranchStatement, p: var PrinterState) =
  p.printMe "BranchStatement"
  p.push 2 + b.then.len
  p.printChild(b.condition)
  for statement in b.then:
    p.printChild(statement)
  p.printChild(b.elseBranch)
  p.pop

# Utility
proc print(f: FunctionDecl, p: var PrinterState) =
  p.printMe "FunctionDecl"
  var children = 1 + f.parameters.len
  if f.returnType.isSome:
    inc children

  p.push children
  p.printChild(f.name)
  for param in f.parameters:
    p.printChild(param)
  if f.returnType.isSome:
    p.printChild(f.returnType.get())
  p.pop

# Expressions
method print(e: Expression, p: var PrinterState) {.base.} =
  p.printMe "Expression"

method print(b: BinaryExpression, p: var PrinterState) =
  p.printMe "BinaryExpression"
  p.push 3
  p.printChild(b.left)
  p.printChild(b.operator)
  p.printChild(b.right)
  p.pop

method print(u: UnaryExpression, p: var PrinterState) =
  p.printMe "UnaryExpression"
  p.push 2
  p.printChild(u.operator)
  p.printChild(u.operand)
  p.pop

method print(c: CallExpression, p: var PrinterState) =
  p.printMe "CallExpression"
  p.push 1 + c.parameters.len
  p.printChild(c.operand)
  for param in c.parameters:
    p.printChild(param)
  p.pop

method print(f: FieldAccessExpression, p: var PrinterState) =
  p.printMe "FieldAccessExpression"
  p.push 2
  p.printChild(f.operand)
  p.printChild(f.field)
  p.pop

method print(s: SubscriptExpression, p: var PrinterState) =
  p.printMe "SubscriptExpression"
  p.push 2
  p.printChild(s.operand)
  p.printChild(s.subscript)
  p.pop

method print(a: Atom, p: var PrinterState) =
  p.printMe "Atom"
  p.push 1
  p.printChild(a.value)
  p.pop

proc print(t: Token, p: var PrinterState) =
  echo t

proc printMe(p: var PrinterState, name: string) =
  echo name

proc printChild[T](p: var PrinterState, child: T) =
  stdout.write p.generateHeader
  p.decChildren
  print(child, p)

proc printTree*[T](tree: T) =
  var p = initPrinterState()
  print(tree, p)
