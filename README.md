# ISA-Exploratorium
Computer architecture designs of all varieties including RISC, CISC, stack and accumulator.  Many are legacy upgrades, i.e. modifications to existing architectures that increase data types, data sizes, and correct problems.
## LEM
Logic Emulation Machine
Accumulator size varies, has carry bit, 9 and 18-bit instructions  
Very simple mostly Boolean operations and add with carry  
### LEM1_9min  
Extremely basic: do Boolean or add with carry instructions until halt instruction  
Repeat after start signal  
### LEM1_9
Logic Emulation Machine with one bit accumulator and 9-bit instructions  
Has conditional branches and subroutine stack  
### LEM1_9ptr  
Logic Emulation Machine: one bit accumulator, nine & 18=bit instructions  
Has four pointer registers with four addressing modes  
Indirect, autoincrement, autodecrement, and pointer plus offset  
### LEM4_9
Logic Emulation Machine with four bit accumulator and 9-bit instructions  
Has conditional branches and subroutine stack, both binary and BCD addition    
### LEM4_9ptr  
Logic Emulation Machine: one bit accumulator, nine & 18=bit instructions  
Both binary and BCD addition.  Has four pointer registers with four addressing modes  
Indirect, autoincrement, autodecrement, and pointer plus offset  
### LEM16_18M  
Combination of bit field instructions and accumulator ISA  
16-bit data memory and 18-bit instructions  
## ROIS  
Register Oreinted Instructon Set, typical RISC with 24-bit instructions  
### ROIS24_24  
24-bit instructions and data, 64 registers, upto 64 instruction codes    
### ROIS24_3sz  
24-bit instructions, 8 16 and 24-bit data, uses all 64 instruction codes  
## TROC  
Tagged Register Oriented Computer  
Register file has additional bits for each register: data type and additional floating-point exponent and mantissa bits  
Each variant supports four data types and four data sizes.  
### TROC16  
Register file of 32 16-bit registers each having four tag bits: 2 type bits and 2 exponent bits  
Is a sub set of the TROC architecture supporting 16-bit instrucitons and 16-bit data only  
### TROC24  
Register file of 32 24-bit registers each having eight tag bits: 2 type, 2 exponent, 4 mantissa  
