=============
Constant Pool
=============

A sequence of constants.  A constant can be one of the following.

Signed integer
--------------
A signed integer from 8 to 64 bits.

Unsigned integer
----------------
An unsigned integer from 8 to 64 bits.

Floating point
--------------
A floating point value either 32 or 64 bits.

String
------
A UTF-8 encoded string.

Function definition
-------------------
Defines the address the function starts at, number of parameters to pop off the
stack and number of locals are available.

Struct definition
-----------------
Contains the size of the structure and an index of byte offsets for all fields.

Interface definition
--------------------
Contains an index of function addresses.  Must be the same order as the
interface definition.

============
Instructions
============

Instructions are an unsigned 8-bit integer (byte) with optional operands.

Format for the instructions are:

INSTRUCTION_NAME[.OPERAND_TYPE] OPERAND

====
Data
====

ldconst.[u8|u16|u32] INDEX
--------------------------
Pushes a the constant at INDEX onto the stack.

pop
---
Pops the value at the top of the stack.

stlocal.[u8 | u16 | u32] INDEX
--------------------------
Stores the value at the top of the stack to the local at INDEX.

ldlocal.[u8|u16|u32] INDEX
--------------------------
Loads the value from the local at INDEX to the top of the stack.

Math
====

addi
subi
muli
divi
modi

addu
subu
mulu
divu
modu

addf
subf
mulf
divf
modf

Branching
=========

testeq
------
Pops top two values off of the stack and comapres if they are equal.  The
result is a byte containing 1 or 0 pushed onto the stack.

testne
------
Pops top two values off of the stack and comapres if they are not equal.  The
result is a byte containing 1 or 0 pushed onto the stack.

testgt
------
Pops top two values off of the stack and comapres if the .  The
result is a byte containing 1 or 0 pushed onto the stack.

testlt
------



jmp[.u8|.u16|.u32|.u64] ADDRESS
-------------------------------
Jump to ADDRESS

jmpt[.u8|.u16|.u32|.u64] ADDRESS
jmpf[.u8|.u16|.u32|.u64] ADDRESS

callfunc[.u8|.u16|.u32|.u64] INDEX
----------------------------------
Calls a function at constant INDEX.  Pushes a stack frame containing return
address.
The number of parameters specified are popped off the stack and stored in
the locals.

callinterface[.u8|.u16|.u32|.u64] INDEX
---------------------------------------
Pops the value at the top of the stack and uses the value to lookup the
interface in the constant pool.  The INDEX is used to select the function
and perform a call.  The number of parameters are popped off the stack and
stored in the locals.

Objects
=======

newstruct[.u8|.u16|.u32|.u64] INDEX
-----------------------------------
Allocate a new object on the heap using the constant struct found at INDEX in
the constant pool.  The pointer address is pushed onto the stack.

newstructarray[.u8|.u16|.u32|.u64] INDEX
----------------------------------------
Allocate a new object array on the heap using the constant struct found at
INDEX in the constant pool.  The value at the top of the stack is popped and
used as the size of the array.  The pointer address is pushed onto the stack.
