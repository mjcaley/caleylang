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

method print(e: Expression, p: var PrinterState) {.base.} =
  p.printMe "Expression"

method print(b: BinaryExpression, p: var PrinterState) =
  p.printMe "BinaryExpression"
  p.push 3
  p.printChild(b.left)
  p.printChild(b.operator)
  p.printChild(b.right)
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

# on entry print this node's header and name
# decrement number of children for top
# push a new Node with the number of children
# on exit pop number of children

proc printTree*[T](tree: T) =
  var p = initPrinterState()
  print(tree, p)


when isMainModule:
  let tokens = lexString("1 + 2")
  let tree = parse(tokens)
  printTree(tree)
