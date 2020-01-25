import parseopt, sequtils, strutils, tables
import parser, ast


const StackSize = 100

type
  Args = object
    files: seq[string]

  Instruction {.size: sizeof(byte).} = enum
    halt,

    pushb
    addb,
    subb,
    mulb,
    divb,
    modb,

    pushaddr
    addaddr,
    subaddr,
    muladdr,
    divaddr,
    modaddr,
    
    pushi8
    addi8,
    subi8,
    muli8,
    divi8,
    modi8,
    
    pushu8
    addu8,
    subu8,
    mulu8,
    divu8,
    modu8,
    
    pushi16
    addi16,
    subi16,
    muli16,
    divi16,
    modi16,
    
    pushu16
    addu16,
    subu16,
    mulu16,
    divu16,
    modu16,
    
    pushi32
    addi32,
    subi32,
    muli32,
    divi32,
    modi32,
    
    pushu32
    addu32,
    subu32,
    mulu32,
    divu32,
    modu32,
    
    pushi64
    addi64,
    subi64,
    muli64,
    divi64,
    modi64,

    pushu64
    addu64,
    subu64,
    mulu64,
    divu64,
    modu64,

    pushf32
    addf32,
    subf32,
    mulf32,
    divf32,
    modf32,

    pushf64
    addf64,
    subf64,
    mulf64,
    divf64,
    modf64,

    jmp,      # (pc)
    jmpeq,    # (pc), jumps to IP if the operands on top of the stack are equal
    jmpneq,   # (pc), jumps to IP if the operands on top of the stack are not equal

    newobj,   # (constant index), constructs object from constant into memory, pushes addr

    pop,
    call,     # (function index), calls function described in function table
    ret       # (), returns to 

  Frame* = object
    retIP*: Natural
    locals*: seq[Value]

  FunctionKind* = enum
    funcNative,
    funcNormal

  Function* = object
    case kind*: FunctionKind
    of funcNative:
      funcPointer*: proc(env: var Environment)
    of funcNormal:
      address*: Natural
    name*: string
    numLocals*: Natural
    numParams*: Natural

  ConstantKind* = enum
    conNativeFunction,
    conFunction,
    conString

  Constant* = object
    case kind*: ConstantKind
    of conFunction:
      fun*: Function
    of conString:
      str*: string
    else:
      discard

  ValueKind* = enum
    valByte,
    valAddr,
    valInt8,
    valUInt8,
    valInt16,
    valUInt16,
    valInt32,
    valUInt32,
    valInt64,
    valUInt64,
    valFloat32,
    valFloat64,
    valStr

  Value* = object
    case kind*: ValueKind
    of valByte:
      b*: byte

    of valAddr:
      a*: pointer

    of valInt8:
      i8*: int8
    of valUInt8:
      u8*: uint8
    of valInt16:
      i16*: int16
    of valUInt16:
      u16*: uint16
    of valInt32:
      i32*: int32
    of valUInt32:
      u32*: uint32
    of valInt64:
      i64*: int64
    of valUInt64:
      u64*: uint64
    
    of valFloat32:
      f32*: float32
    of valFloat64:
      f64*: float64

    of valStr:
      s*: string

  Environment* = object
    ip*: Natural
    program*: seq[byte]
    operandStack*: seq[Value]
    callStack*: seq[Frame]
    constants*: seq[Constant]


proc initEnvironment() : Environment =
  result = Environment(
    ip: 0,
    program: newSeq[byte](),
    operandStack: newSeq[Value](),
    callStack: newSeq[Frame](),
    constants: newSeq[Constant]()
  )

proc `$`(e: Environment) : string =
  result = "Environment\n" &
    "Constants\n---------\n" &
    "\t" & $e.constants & "\n" &
    "Operand Stack\n-------------\n" &
    "\t" & $e.operandStack & "\n" &
    "Call Stack\n----------\n" &
    "\t" & $e.callStack & "\n" &
    "Program\n-------\n"

  const defaultLimit = 16
  var lineLimit = defaultLimit
  for code in e.program:
    if lineLimit == 0:
      result &= "\n"
      lineLimit = defaultLimit
    result &= " " & code.toHex
    dec lineLimit

proc pushFrame(env: var Environment, f: Function) =
  var frame = Frame(retIP: env.ip, locals: newSeq[Value](f.numLocals))
  for param in 0..<f.numParams:
    frame.locals[param] = env.operandStack.pop
  env.callStack.add(frame)
  env.ip = f.address

proc popFrame(env: var Environment) =
  let frame = env.callStack.pop
  env.ip = frame.retIP

proc environmentStatus(env: Environment) : string =
  result = "IP: " & $env.ip & "\nOperand stack: " & $env.operandStack & "\nCallStack: " & $env.callStack

#region Byte conversion
proc toBytes[T](v: T) : array[sizeof(T), byte] =
  const size = sizeof(T) - 1
  result = cast[array[0..size, byte]](v)
  
proc fromBytes[T](v: openArray[byte], index: Natural) : T =
  result = (cast[ptr T](unsafeAddr v[index]))[]
  
proc fromBytes[T](v: var openArray[byte], index: Natural) : T =
  result = (cast[ptr T](addr v[index]))[]
  
# echo "Integer to bytes (42)"
# let b42 = toBytes[int64](42)
# echo b42

# echo "Bytes to integer (42)"
# let i42 = fromBytes[int64](b42, 0)
# echo i42

# echo "var Bytes to integer (42)"
# var vi42 = fromBytes[int64](b42, 0)
# echo vi42

#endregion

proc basicProgram(env: var Environment) =
  env.program = @[byte(call)] & @(toBytes[Natural](0)) & @[byte(halt), byte(pushi32)] & @(toBytes[int32](40)) & @[byte(pushi32)] & @(toBytes[int32](2)) & @[byte(addi32), byte(ret)]
  env.constants.add(
    Constant(
      kind: conFunction,
      fun: Function(
        kind: funcNormal,
        address: 10,
        name: "main()",
        numParams: 0,
        numLocals: 0
      )
    )
  )



proc print[T](i: Instruction, message: T) =
  echo "[", $i, "]", " ", $message

proc print(i: Instruction) =
  print(i, "")

proc consumeInstruction(env: var Environment) : Instruction =
  result = Instruction env.program[env.ip]
  inc env.ip

proc arg[T](env: var Environment) : T =
  result = fromBytes[T](env.program, env.ip)
  env.ip += sizeof(T)

proc argbyte(env: var Environment) : byte =
  result = arg[byte](env)

proc argint8(env: var Environment) : int8 =
  result = arg[int8](env)

proc arguint8(env: var Environment) : uint8 =
  result = arg[uint8](env)

proc argint16(env: var Environment) : int16 =
  result = arg[int16](env)

proc arguint16(env: var Environment) : uint16 =
  result = arg[uint16](env)

proc argnatural(env: var Environment) : Natural =
  result = arg[Natural](env)

proc top(env: var Environment) : Value =
  result = env.operandStack[env.operandStack.high]

proc push(env: var Environment, value: Value) =
  env.operandStack.add(value)

proc popValue(env: var Environment) : Value =
  result = env.operandStack.pop

proc loop(env: var Environment) : int =
  var running = true
  while running:
    echo env.environmentStatus
    case Instruction env.consumeInstruction:
      of halt:
        running = false
        print(halt)
      of call:
        let funcIndex = env.argnatural
        let function = env.constants[funcIndex].fun
        env.pushFrame(function)
        print(call, $funcIndex)
      of ret:
        env.popFrame()
        print(ret)
      of pushb:
        let arg = env.argbyte
        env.push(Value(kind: valByte, b: arg))
        print(pushb, $arg)
      of pop:
        discard env.popValue
        print(pop)
      of addb:
        let right = env.popValue
        let left = env.popValue
        env.push(Value(kind: valByte, b: left.b + right.b))
        print(addb)
      else:
        running = false

proc main() =
  var filenames = newSeq[string]()
  var optParser = initOptParser()
  for kind, key, value in optParser.getopt():
    case kind
    of cmdArgument:
      filenames.add(value)
    else:
      discard

  # Parse files
  # var modules = newTable[string, Module]()
  # let mainModule = filenames[0]
  # for filename in filenames:
  #   let parseResult = parseFile(filename)
  #   if parseResult.errors.len > 0:
  #     echo "Found errors when parsing: "
  #     for error in parseResult.errors:
  #       echo "Error @ ", error.position.line, ":", error.position.column, " :: ", error.name, " ", error.message
  #     break
  #   else:
  #     let ast = treeToAst(parseResult.tree)
  #     modules.add(filename, ast)

  # Setup VM
  var env = initEnvironment()
  basicProgram(env)
  echo env
  let returnCode = loop(env)
  echo "Stack: ", env.operandStack
  echo "Exiting (", returnCode, ")"

when isMainModule:
  main()
