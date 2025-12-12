# ISA-Exploratorium
Welcome to my collection of original computer designs  
Designs of all varieties including RISC, CISC, stack and accumulator  
They are in various stages of completion  
With ~six having working test benches  
Many files have a six digit date suffix of year, month and day  
### A work in progess  
Beware many of the projects and their ISAs in _all_projects are incomplete  
Use the spreadsheet to examine their status  
## _all_projects  
Project files for individual designs  
Often containing numerals for data and instruction size  

There has been an evolution of design criterial over time (30+ years)  
Thus each project has a prefix giving the year of the first basic description  

### A complete design has:
README.md and  
A "glossy" documentation file containing a basic description  
A formal doc file containing a full description of each instruction, addressing modes and memory layout  
A spreadsheet file listing all the instructions and their encoding  
A business case file giving the rational  
FPGA project/zip archive file containing RTL source, constraint file, testbench  
PDF versions of spreadsheet sheets are included for ease of review and printout  

Needless to say, only a few designs are this complete  
And one would like to have an assembler and compiler as well  

# Here are the design categories  

## ALT_uPs
Legacy upgrades, i.e. modifications to existing architectures that increase data types, data sizes, and correct problems  

## BCD  
Variable length Binary Coded Decimal arithmetic  
Memory to memory architecture  

## LEM
Logic Emulation Machine  
Accumulator size of one or four bits, has carry bit, nine and 18-bit instructions  
Very simple mostly Boolean operations and add with carry  
### LEM1_9, LEM1_9ptr, LEM4_9 and LEM4_9ptr are complete  

## MAOC aka CISC  
Multi-accumulator oriented computer  
Opertaions take place between registers and between registers and memory  

## OOSM  
One operand stack machine  
An attempt to squeeze as much functionality out of a single stack instruction  
Thereby improving work done per instruction while maintaining code density  

## quadISA aka ALT_All  
An attempt to provide RISC, CISC, Stack and Accumulator instructions within a single ISA  

## ROIS aka ROC  
Register Oreinted Instructon Set, typical RISC with 24-bit and larger instructions  
Name changed to ROC (Register Oriented Computer) for better pronounciation and dramatic effect  
### ROIS24_24min is complete  

## TROC  
Tagged Register Oriented Computer  
Register file has additional bits on each register:
 data type & additional floating-point exponent and mantissa/fraction bits  
Each variant supports four data types and four data sizes  
Various un-tagged register bit length of 16, 24, 32, 36, 42, 48 and 64-bits  
The corresponding byte sizes are       8, 8 or 12, 8, 9, 21, 8 or 12 and 8-bits  
Instruction lengths and immediate values vary in length with 24-bit instructions dominating  
### TROC16 is complete, needs more testing  

## Implementation:  
Oriented towards FPGA implementation  
Single cycle execution for register to register instructions  
Dual port block RAM arranged for single cycle readout of unaligned instructions and data  
No micrco-code, no data path planning  
Common sub-expressions identified by assignment to a distinct name  
Separate register update process  
In the case of TROC instructions defined/expressed via three nested case statements  
-Instruction size, e.g. a section for each instruction size  
--Each distinct instruction with some merged  
---Each data type as needed  
In addition there is an outer case for state handling, mostly memory read/write states  
