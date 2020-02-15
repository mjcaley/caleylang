type
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