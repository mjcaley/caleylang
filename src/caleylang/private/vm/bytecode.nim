type
  Instruction* {.size: sizeof(byte).} = enum
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
    ret       # (), set PC to the return address in the frame, pops the frame
