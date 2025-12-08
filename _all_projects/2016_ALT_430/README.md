## ALT_430  
Intented to provide increased capability to the Texas Instruments MSP430 ISA  
The register size in the register file is increased to the larger of the address size  
or the data size  
The BCD instruction is used to escape to a 24-bit instruction  
The original 16-bit instructions apply to the byte and largest data size  
The 24-bit instructions support three data sizes and three data types  
along with a larger set of operation codes  
The set of available registers is reduced to fourteen in order to support five addressing modes  
-register  
-register indirect  
-register indirect with pre-decrement  
-register indirect with post-increment  
-register indirect with offset value  
Additionally there is support for immediate values within the instruction stream  
