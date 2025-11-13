# ISA-Exploratorium
## work in progess, known errors  
Computer architecture designs of all varieties including RISC, CISC, stack and accumulator.  

## _all_projects  
Project files for individual designs  

There has been an evolution of design criterial over time (30+ years)  
Thus each project has a prefix giving the year of the first basic description  

A complete design has:
README.md
A docx file containing a basic description  
A formal doc file containing a full description of each instruction, addressing modes and memory layout  
A xlsx file listing all the instructions and their encoding  
A business case file giving the rational  
A FPGA project/zip file containing RTL source, constraint file, testbench  

Needless to say, only a few designs are this complete  
And one would like to have an assembler and compiler as well  

# Here are the design categories  

## ALT_uPs
Legacy upgrades, i.e. modifications to existing architectures that increase data types, data sizes, and correct problems.

## BCD  
Variable length Binary Coded Decimal arithmetic  
Memory to memory architecture  

## LEM
Logic Emulation Machine  
Accumulator size of one or four bits, has carry bit, nine and 18-bit instructions  
Very simple mostly Boolean operations and add with carry  

## MAOC aka CISC  
Multi-accumulator oriented computer  
Opertaions take place between registers and between registers and memory  

## OOSM  
One operand stack machine  
An attempt to squeeze as much functionality out of a single stack instruction  
Thereby improving work done per instruction and maintaining code density  

## quadISA aka ALT_All  
An attempt to provide RISC, CISC, Stack and Accumulator instructions within a single ISA  

## ROIS aka ROC  
Register Oreinted Instructon Set, typical RISC with 24-bit and larger instructions  
Name changed to ROC (Register Oriented Computer) for better pronounciation and dramatic effect  

## TROC  
Tagged Register Oriented Computer  
Register file has additional bits on each register:
 data type & additional floating-point exponent and mantissa/fraction bits  
Each variant supports four data types and four data sizes  
Various un-tagged register bit lenghts of 16, 24, 32, 36, 42, 48 and 64-bits  
The corresponding byte sizes are        8, 8 or 12, 8, 9, 21, 8 or 12 and 8-bits  
Instruction lengths and immediate values vary in length with 24-bit instructions dominating  
