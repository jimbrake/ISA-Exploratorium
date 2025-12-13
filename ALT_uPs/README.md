## ALT_uPs  
Alternate versions of, or legacy updates of "early" computers  

### alt_430  
#### Derived from Texas Instruments MSP430, a low power 16-bit processor  
Additional addressing mode indirect autodecrement reducing the register file to 14 registers  
Registers lengthened to provide larger address space and larger data items  
BCD instruction repurposed to provide an escape to 24-bit instructions and additional data sizes and types  
The 16-bit instructions support byte and max length data; 2's complement only  

### alt_11  
#### Derived from Digital Equipment PDP-11, 16-bit mini-computer  
Addressing modes prunned to ~five, no double indirect.  Register file increased to 12 registers. 
Registers lengthened to provide larger address space and larger data items  
Floating-point instruction repurposed to provide an escape to 24-bit instructions and additional data sizes and types  
The 16-bit instructions support byte and max length data, 2's complement only  

### alt_vax  
#### Derived from Digital Equipment VAX-780, 32-bit upgrade from PDP11  
Addressing modes prunned to ~five, no double indirect.  Single data memory reference  
Registers lengthened to provide larger address space and larger data items  
Except for a few 16-bit instructions most instructions are 24-bits  
Three register fields and a single memory address mode field, 8-bit opcode  
The addressing mode field applies to either one source or the destination  
Eight addressing modes are possible  
Indexed addressing is via a prefix byte which identifies the index register  

### alt_x86  
#### Derived from Intel/AMD x86 processor  
A complete rearrangement of the ISA with most instructions 24-bits  
No prefix codes  
A register file of 16 registers and x86 addressing modes
No MMX instructions at this time  

### *alt_RISC-v* or *alt_MIPS*  
#### RISC machines with 24-bit instructions, four data types and four data sizes  
See **RIOS**, **ROC** or **TROC**
### alt_1604  
#### Derived from CDC 1604 scientific computer  
Accumulator, auxillary register (Q) and six index regsiters all of the same bit length  
Most instructions retainded.  2's complement instead of one's complement  

### alt_1620  
#### Derived from IBM 1620 varialble length decimal computer  
See *radix10* aka **BCD1** and *radix100* aka **BCD2** ISAs  


