import parseopt, sequtils, strutils, tables
import private/vm/bytecode, parser, ast

type
  Args = object
    files: seq[string]

  Frame* = object
    retIP*: Natural
    locals*: seq[Value]

  FunctionKind* = enum
    funcNative,
    funcNormal

  FunctionDefinition* = object
    case kind*: FunctionKind
    of funcNative:
      funcPointer*: proc(env: var Environment)
    of funcNormal:
      address*: int
    name*: string
    numLocals*: int
    numParams*: int

  InterfaceDefinition* = object
    name*: string
    functionAddrs*: seq[int]
  
  StructDefinition* = object
    name*: string
    size*: int
    fieldOffsets*: seq[int]

  ConstantKind* = enum
    conUInt8,
    conUInt16,
    conUInt32,
    conUInt64,
    conInt8,
    conInt16,
    conInt32,
    conInt64,
    conFloat32,
    conFloat64,
    conString,
    conFunction,
    conStruct,
    conInterface

  Constant* = object
    case kind*: ConstantKind
    of conUInt8, conUInt16, conUInt32, conUInt64:
      uinteger*: BiggestUInt
    of conInt8, conInt16, conInt32, conInt64:
      integer*: BiggestInt
    of conFloat32, conFloat64:
      floatingPoint*: float64
    of conString:
      str*: string
    of conFunction:
      functionDef*: FunctionDefinition
    of conStruct:
      structDef*: StructDefinition
    of conInterface:
      interfaceDef*: InterfaceDefinition

  ValueKind* = enum
    valNone,
    valAddr,
    valPtr,
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
    of valNone:
      discard
    of valAddr:
      a*: int

    of valPtr:
      p*: pointer

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

  VMRuntimeError* = object of Exception


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

proc currentFrame(env: var Environment) : var Frame =
  env.callStack[high env.callStack]

proc pushFrame(env: var Environment, f: FunctionDefinition) =
  var frame = Frame(retIP: env.ip, locals: newSeq[Value](f.numLocals))
  for param in 0..<f.numParams:
    frame.locals[param] = env.operandStack.pop
  env.callStack.add(frame)
  env.ip = f.address

proc popFrame(env: var Environment) =
  let frame = env.callStack.pop
  env.ip = frame.retIP

proc environmentStatus(env: Environment) : string =
  result = "----------------\n" & "IP: " & $env.ip & "\nOperand stack: " & $env.operandStack & "\nCallStack: " & $env.callStack & "\n----------------"

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


proc printNative(env: var Environment) =
  let param = env.currentFrame().locals[0]
  case param.kind:
    of valUInt8:
      echo param.u8
    else:
      echo "printNative, type not implemented"
  discard env.callStack.pop()

proc basicProgram(env: var Environment) =
  env.program = @[
    byte(callfunc_u8), 2,
    byte(callfunc_u8), 4,
    byte(halt),
    # main() : u8
    byte(ldconst_u8), 0,
    byte(ldconst_u8), 1,
    byte(callfunc_u8), 3, # sum(40, 2)
    byte(ret),
    # sum(a, b) : u8
    byte(ldlocal_u8), 0,  # first param
    byte(ldlocal_u8), 1,  # second param
    byte(addu),
    byte(ret)
    ]
  env.constants.add(
    Constant(
      kind: conUint8,
      uinteger: 40
    )
  )
  env.constants.add(
    Constant(
      kind: conUint8,
      uinteger: 2
    )
  )
  env.constants.add(
    Constant(
      kind: conFunction,
      functionDef: FunctionDefinition(
        kind: funcNormal,
        address: 5,
        name: "main()",
        numParams: 0,
        numLocals: 1
      )
    )
  )
  env.constants.add(
    Constant(
      kind: conFunction,
      functionDef: FunctionDefinition(
        kind: funcNormal,
        address: 12,
        name: "sum()",
        numParams: 2,
        numLocals: 2
      )
    )
  )
  env.constants.add(
    Constant(
      kind: conFunction,
      functionDef: FunctionDefinition(
        kind: funcNative,
        name: "print()",
        funcPointer: printNative,
        numParams: 1,
        numLocals: 1
      )
    )
  )

proc fibProgram(env: var Environment) =
  env.program = @[
    byte(ldconst_u8), 0,
    byte(callfunc_u8), 3,
    byte(callfunc_u8), 4,
    byte(halt),
    # fib(n)
    byte(ldlocal_u8), 0,
    byte(ldconst_u8), 2,
    byte(testltu),      # if n < 2
    byte(jmpf_u8), 17, # to recursive calls
    byte(ldlocal_u8), 0,
    byte(ret),

    byte(ldlocal_u8), 0,
    byte(ldconst_u8), 1, # 1
    byte(subu),
    byte(callfunc_u8), 3, # fib(n - 1)
    byte(ldlocal_u8), 0,
    byte(ldconst_u8), 2, # 2
    byte(subu),
    byte(callfunc_u8), 3, # fib(n - 2)
    byte(addu),
    byte(ret),
    ]
  env.constants.add(
    Constant(
      kind: conUint8,
      uinteger: 10
    )
  )
  env.constants.add(
    Constant(
      kind: conUint8,
      uinteger: 1
    )
  )
  env.constants.add(
    Constant(
      kind: conUint8,
      uinteger: 2
    )
  )
  env.constants.add(
    Constant(
      kind: conFunction,
      functionDef: FunctionDefinition(
        kind: funcNormal,
        address: 7,
        name: "fib()",
        numParams: 1,
        numLocals: 1
      )
    )
  )
  env.constants.add(
    Constant(
      kind: conFunction,
      functionDef: FunctionDefinition(
        kind: funcNative,
        name: "print()",
        funcPointer: printNative,
        numParams: 1,
        numLocals: 1
      )
    )
  )

#region VM utility

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

#endregion

proc coerceUnsigned(val: Value) : BiggestUInt =
  case val.kind:
  of valUInt8:
    result = val.u8
  of valUInt16:
    result = val.u16
  of valUInt32:
    result = val.u32
  of valUInt64:
    result = val.u64
  else:
    discard

proc coerceSigned(val: Value) : BiggestInt =
  case val.kind:
  of valAddr:
    result = val.a
  of valInt8:
    result = val.i8
  of valInt16:
    result = val.i16
  of valInt32:
    result = val.i32
  of valInt64:
    result = val.i64
  else:
    discard

proc coerceFloat(val: Value) : BiggestFloat =
  case val.kind:
  of valFloat32:
    result = val.f32
  of valFloat64:
    result = val.f64
  else:
    discard


proc loop(env: var Environment) : int =
  var running = true

  while running:
    # echo env.environmentStatus
    let currentInstruction: Instruction = env.consumeInstruction
    # echo "Current instruction: ", currentInstruction

    case currentInstruction:  # TODO: should check if out of range
      of halt:
        running = false

      of Instruction.pop:
        discard env.operandStack.pop()

      of ldconst_u8:
        let operand = env.arguint8()
        let constant = env.constants[operand]
        case constant.kind:
        of conUInt8:
          env.operandStack.add(Value(kind: valUInt8, u8: uint8 constant.uinteger))
        else:
          raise newException(VMRuntimeError, "ldconst.u8 expected a uint8 constant, but got" & $constant)

      of ldlocal_u8:
        let index = env.arguint8()
        let local = env.currentFrame.locals[index]
        env.operandStack.add(local)

      of stlocal_u8:
        let index = env.arguint8()
        env.currentFrame.locals[index] = env.operandStack.pop()

      of callfunc_u8:
        let index = env.arguint8()
        let function = env.constants[index].functionDef

        env.callStack.add(Frame(retIP: env.ip, locals: newSeq[Value](function.numLocals)))
        for i in 0..<function.numParams:
          env.currentFrame.locals[i] = env.operandStack.pop()

        case function.kind:
        of funcNormal:
          env.ip = function.address
        of funcNative:
          function.funcPointer(env)

      of ret:
        let frame = env.callStack.pop()
        env.ip = frame.retIP

      of addu:
        let second = env.operandStack.pop()
        let first = env.operandStack.pop()

        # assume uint8
        let sum = first.u8 + second.u8
        env.operandStack.add(Value(kind: valUInt8, u8: sum))

      of subu:
        let second = env.operandStack.pop()
        let first = env.operandStack.pop()

        # assume uint8
        let sum = first.u8 - second.u8
        env.operandStack.add(Value(kind: valUInt8, u8: sum))

      of newstruct_u8:
        let index = env.arguint8()
        let struct = env.constants[index].structDef
        let structAddr = alloc0(struct.size)
        env.operandStack.add(Value(kind: valPtr, p: structAddr))

      of testequ:
        let first = env.operandStack.pop()
        let second = env.operandStack.pop()

        let test = coerceUnsigned(first) == coerceUnsigned(second)

        if test:
          env.operandStack.add(Value(kind: valUInt8, u8: 1))
        else:
          env.operandStack.add(Value(kind: valUInt8, u8: 0))

      of testltu:
        let second = env.operandStack.pop()
        let first = env.operandStack.pop()

        let test = coerceUnsigned(first) < coerceUnsigned(second)

        if test:
          env.operandStack.add(Value(kind: valUInt8, u8: 1))
        else:
          env.operandStack.add(Value(kind: valUInt8, u8: 0))

      of testgtu:
        let second = env.operandStack.pop()
        let first = env.operandStack.pop()

        let test = coerceUnsigned(first) > coerceUnsigned(second)

        if test:
          env.operandStack.add(Value(kind: valUInt8, u8: 1))
        else:
          env.operandStack.add(Value(kind: valUInt8, u8: 0))

      of jmpt_u8:
        let address = env.arguint8()
        let testResult = env.operandStack.pop()
        if testResult.kind != valUInt8:
          raise newException(VMRuntimeError, "jmpt_u8 must be a uint8")
        if testResult.u8 > uint8 0:
          env.ip = address

      of jmpf_u8:
        let address = env.arguint8()
        let testResult = env.operandStack.pop()
        if testResult.kind != valUInt8:
          raise newException(VMRuntimeError, "jmpt_u8 must be a uint8")
        if testResult.u8 == uint8 0:
          env.ip = address

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

  
  # var env = initEnvironment()
  # basicProgram(env)
  # echo env
  # let returnCode = loop(env)
  # echo "Stack: ", env.operandStack
  # echo "Exiting (", returnCode, ")"

  echo "Fibonacci"
  var fibEnv = initEnvironment()
  fibProgram(fibEnv)
  let fibReturnCode = loop(fibEnv)
  echo environmentStatus(fibEnv)

when isMainModule:
  main()
