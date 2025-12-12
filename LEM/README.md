# LEM  
## Logic Emulation Machine  
Accumulator size varies, has carry bit, 9 and 18-bit instructions.  Very simple mostly Boolean operations and add with carry.  See LEM_exec_sum.docx file for rational.  
## LEM1_9min  
Extremely basic: do sequence of Boolean or add with carry instructions until halt instruction.  Repeat after start signal.  
## LEM1_9  
Logic Emulation Machine with one bit accumulator, nine and 18 bit instructions.  Has conditional branches and subroutine stack.  
## LEM1_9ptr  
Logic Emulation Machine: one bit accumulator, nine and 18 bit instructions.  Has four pointer registers with four addressing modes.  Indirect, autoincrement, autodecrement, and pointer plus offset.  
## LEM4_9  
Logic Emulation Machine with four bit accumulator, nine and 18 bit instructions.  Has conditional branches and subroutine stack, both binary and BCD addition.  
## LEM4_9ptr  
Logic Emulation Machine: four bit accumulator, nine and 18 bit instructions.  Both binary and BCD addition. Has four pointer registers with four addressing modes.  Indirect, autoincrement, autodecrement, and pointer plus offset.  
## LEM16_18M  
Combination of bit field instructions and accumulator ISA.  16-bit data memory using 18 bit instructions.  
