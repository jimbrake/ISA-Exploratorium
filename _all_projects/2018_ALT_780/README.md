## ALT-780  
A design limiting data memory access for a single instruction to a single memory location  
-considered the biggest obstacle to high performance  
ALT-780 uses a 24-bit instruction and an eight bit prefix to specify an index register  
A 24-bit instruction contains an 8-bit op-code, three four bit register designators  
-and a four bit address mode  
One address mode bit indicates if address mode applies to either a source or destination register  
The remaining three bits indicate the address mode
The address modes do not support double indirection as this violates the 
-single data memory location constraint  
There is room in the address modes to specify the size of address offset fields  
-which also increase the instruction length
There are a few 16-bit instructions for memory/register clear/set/increment/decrement  
And a 24-bit instruction for memory to memory move (with two address mode fields)  
The op-codes follow the 780 ISA to a large extent indicating data size and data type  
-as well as the operation  
There are 16 prefix codes, designating the index register  
The register file allocation remains the same with PC, SP & FP present
