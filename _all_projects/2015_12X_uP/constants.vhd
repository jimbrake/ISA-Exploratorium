----------------------------------------------------------------------------------
-- Company:         Brakefield Research
-- Engineer:        James Brakefield
-- 
-- Create Date:     22:28:14 09/29/2015 
-- Design Name:     the12X_12uP
-- Module Name:     constants - Behavioral 
-- Project Name: 
-- Target Devices:  Spartan-6, Xilinx 7 series
-- Tool versions:   ISE 14.7
-- Description:     constants used to configure LUT RAM and block RAM
--                  constants used to generate instructions for block RAM initialization
--
-- Dependencies: 
--
-- Revision 0.9  - fully defined, unimplemented op-codes commented out
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

PACKAGE constants IS

--type state_type is (NORMst, TRAPst, MRDst, MWTst);    -- normal inst, 2nd phase trap inst or branch/call inst, 2nd phase mem read, 2nd phase mem write

constant inst_size          : integer := 12;
constant data_size          : integer := 12;
constant LUTRAM_adr_size    : integer := 6;
constant mem_adr_size       : integer := 9;     -- reduced from 12 for conveinience
constant LUTRAM_size        : integer := 2 ** LUTRAM_adr_size;  -- 64X12 data and return stacks
constant mem_size           : integer := 2 ** mem_adr_size;     -- 4Kx12 program and data memory

--  Op-code modifiers                                   109876543210
constant bit_R      : integer := 6;
constant op_R       : std_logic_vector(11 DOWNTO 0) := "000001000000";  -- bit 6: return flag: pop return stack and jump to the popped value address
constant op_v       : std_logic_vector(11 DOWNTO 0) := "000001000000";  -- bit 6: branch not flag (only for BRZ & BRNZ)
constant bit_P      : integer := 5;                                     -- if set & r=0 then push result, if set & r=1 pop data stack
constant op_P       : std_logic_vector(11 DOWNTO 0) := "000000100000";  -- bit 5: pop/push stack op flag for X=4..31
constant bit_E      : integer := 4;
constant op_E       : std_logic_vector(11 DOWNTO 0) := "000000010000";  -- bit 4: replace operation flag
constant bit_M      : integer := 3;			-- MNNN codes for stack locations (AKA "L(LN)"): 0-6: SP+N, 7: imm at PC+1, 8-14: L-N, 15: RP
constant op_M       : std_logic_vector(11 DOWNTO 0) := "000000001000";  -- bit 3: locals/SP pointer flag, for N=0..6
constant op_SPoff	: std_logic_vector(11 DOWNTO 0) := "000000000000";	-- NNN between 000 and 110, 2nd operand is at SP+NNN
constant op_Loff	: std_logic_vector(11 DOWNTO 0) := "000000001000";	-- NNN between 000 and 110, 2nd operand is at FP-NNN
--constant op_IMM		: std_logic_vector(11 DOWNTO 0) := "000000000111";	-- 2nd operand is at PC+1 (not yet implemented)
--                  if bit_E set, is not valid, could be used for long conditional branches?
constant op_RP		: std_logic_vector(11 DOWNTO 0) := "000000001111";	-- 2nd operand is at RP

--  Op-codes                                            000000XXXXXX                            Miscellaneous and traps
constant op_NOP     : std_logic_vector(11 DOWNTO 0) := "100000000000";  --X= 0      all unimplemented opcodes: PICK from sp 
constant op_TRAP    : std_logic_vector(11 DOWNTO 0) := "000000000000";  --X= 0      indirect call thru address at low memory (not yet implemented) 
constant op_EXTND   : std_logic_vector(11 DOWNTO 0) := "000010000000";  --X= 1      prefix bits to extend meaning of following instruction (not yet implemented) 

--  Op-codes                                            XXXXXRsNNNNN                                Call & branches
constant op_CALL    : std_logic_vector(11 DOWNTO 0) := "000100000000";  --X= 2              push PC+1 onto return stack, jump to PC+/-NNNNN
constant op_BR      : std_logic_vector(11 DOWNTO 0) := "000101000000";  --X= 2 | op_R       "push & pop PC from return stack", jump to PC+/-NNNNN
constant op_BZ      : std_logic_vector(11 DOWNTO 0) := "000110000000";  --X= 3              jump to PC+/-NNNNN if CCR zero flag set
constant op_BNZ     : std_logic_vector(11 DOWNTO 0) := "000111000000";  --X= 3 | op_v       jump to PC+/-NNNNN if CCR zero flag clear

--  Op-codes                                            XXXXXRPEsNNN                                Load/store to block RAM (not yet implemented)
constant op_LD      : std_logic_vector(11 DOWNTO 0) := "001000000000";  --X= 4              load/push block RAM location L(LN)
constant op_ST      : std_logic_vector(11 DOWNTO 0) := "001000010000";  --X= 4              store/pop to block RAM location L(LN)
constant op_LDoff   : std_logic_vector(11 DOWNTO 0) := "001010000000";  --X= 5              load/push block RAM location L(LN)+TOS
constant op_SToff   : std_logic_vector(11 DOWNTO 0) := "001011000000";  --X= 5              store/pop to block RAM location L(LN)+TOS
constant op_LDpp    : std_logic_vector(11 DOWNTO 0) := "001100000000";  --X= 6              load/push block RAM location L(LN)++
constant op_STpp    : std_logic_vector(11 DOWNTO 0) := "001101000000";  --X= 6              store/pop to block RAM location L(LN)++
constant op_LDnn    : std_logic_vector(11 DOWNTO 0) := "001110000000";  --X= 7              load/push block RAM location --L(LN)
constant op_STnn    : std_logic_vector(11 DOWNTO 0) := "001111000000";  --X= 7              store/pop to block RAM location --L(LN)

--  Op-codes                                            XXXXXRPsNNNN                                Immediates
constant op_ANDI    : std_logic_vector(11 DOWNTO 0) := "010000000000";  --X= 8              and +/-NNNN to top of data stack
constant op_ORI     : std_logic_vector(11 DOWNTO 0) := "010010000000";  --X= 9              or +/-NNNN to top of data stack
constant op_XORI    : std_logic_vector(11 DOWNTO 0) := "010100000000";  --X=10              xor +/-NNNN to top of data stack
constant op_LDI     : std_logic_vector(11 DOWNTO 0) := "010110000000";  --X=11              push +/-NNNN onto data stack
constant op_ADDI    : std_logic_vector(11 DOWNTO 0) := "011000000000";  --X=12              add +/-NNNN to top of data stack
constant op_CMPI    : std_logic_vector(11 DOWNTO 0) := "011010000000";  --X=13              compare +/-NNNN to top of data stack
--constant op_SHIFT   : std_logic_vector(11 DOWNTO 0) := "011100000000";  --X=14              shift top of data stack arithmetically left or right

--  Op-codes                                            XXXXXXXXNNNN                                Specials
--constant op_LUT     : std_logic_vector(11 DOWNTO 0) := "01111000NNNN";  --X=15      extract field from LUT table (not yet implemented)
--constant op_CASEB   : std_logic_vector(11 DOWNTO 0) := "01111001NNNN";  --X=15      branch to address in following table (not yet implemented)
--constant op_CASEC   : std_logic_vector(11 DOWNTO 0) := "01111010NNNN";  --X=15      call subroutine from address in following table (not yet implemented)
--constant op_EXTRCT  : std_logic_vector(11 DOWNTO 0) := "01111011NNNN";  --X=15      TOS>>N, TOS and 2**N-1 (not yet implemented)
--constant op_PACK    : std_logic_vector(11 DOWNTO 0) := "01111100NNNN";  --X=15      SOS<<N or TOS and 2**N-1 (not yet implemented)
--constant op_MULI    : std_logic_vector(11 DOWNTO 0) := "01111101NNNN";  --X=15      multiple TOS by 4-bit unsigned immediate (not yet implemented)
--  Op-codes                                            XXXXXXXXXXXX                                Specials without parameters
--constant op_SPEC    : std_logic_vector(11 DOWNTO 0) := "0111111XXXXX";  --X=15      catch-all for useful op-codes (not yet implemented)

--  Op-codes                                            XXXXXRPEMNNN                                LUT RAM data move
constant op_PICK    : std_logic_vector(11 DOWNTO 0) := "100000000000";  --X=16                  load/push from offset stack location
constant op_POCK    : std_logic_vector(11 DOWNTO 0) := "100000010000";  --X=16        | op_E    store/pop to offset stack location
constant op_IN      : std_logic_vector(11 DOWNTO 0) := "100010000000";  --X=17                  input from port NNNN
constant op_OUT     : std_logic_vector(11 DOWNTO 0) := "100010010000";  --X=17        | op_E    output to port NNNN
constant op_POPFP   : std_logic_vector(11 DOWNTO 0) := "100100000000";  --X=18                  pop frame pointer and adjust stack pointer
constant op_PUSHFP  : std_logic_vector(11 DOWNTO 0) := "100100010000";  --X=18        | op_E    push frame pointer and update to offset stack pointer
constant op_EXEC    : std_logic_vector(11 DOWNTO 0) := "100101010000";  --X=18 | op_P | op_E    call subroutine at location L(MNNN)
constant op_DROPn   : std_logic_vector(11 DOWNTO 0) := "100100100000";  --X=18                  multi-word drop, e.g. add N to stack pointer
--constant op_INITstk : std_logic_vector(11 DOWNTO 0) := "100100110000";  --X=18        | op_E    copy words from PC+1..n to stack, a multi-cycle inst.
--                                                                                                  ALU operations
constant op_INC     : std_logic_vector(11 DOWNTO 0) := "100110000000";  --X=19              increment contents of location MNNN in LUT RAM
constant op_DEC     : std_logic_vector(11 DOWNTO 0) := "100110010000";  --X=19 | op_P       decrement contents of location MNNN in LUT RAM
constant op_CLR     : std_logic_vector(11 DOWNTO 0) := "100110100000";  --X=19        | op_E    clear contents of location MNNN in LUT RAM
constant op_SET     : std_logic_vector(11 DOWNTO 0) := "100110110000";  --X=19 | op_P | op_E    set contents of location MNNN in LUT RAM to all 1s
constant op_ADD     : std_logic_vector(11 DOWNTO 0) := "101000000000";  --X=20              add contents of location MNNN to TOS
constant op_SUB     : std_logic_vector(11 DOWNTO 0) := "101010000000";  --X=21              subtract contents of location MNNN from TOS
constant op_MUL     : std_logic_vector(11 DOWNTO 0) := "101100000000";  --X=22              multiply contents of location MNNN by TOS
constant op_DIV     : std_logic_vector(11 DOWNTO 0) := "101110000000";  --X=23              divide contents of location MNNN by TOS
constant op_LOOPCC  : std_logic_vector(11 DOWNTO 0) := "101111000000";  --X=23              branch to L(RP) if condition is true
constant op_GENRTNCC: std_logic_vector(11 DOWNTO 0) := "101111010000";  --X=23              push 1 else 0 and return if condition is true
constant op_GENCC   : std_logic_vector(11 DOWNTO 0) := "101111100000";  --X=23              push 1 else 0 if condition is true
constant op_XGENCC  : std_logic_vector(11 DOWNTO 0) := "101111110000";  --X=23              push 1 else 0 if exteneded condition is true
constant op_AND     : std_logic_vector(11 DOWNTO 0) := "110000000000";  --X=24              and contents of location MNNN with TOS
constant op_OR      : std_logic_vector(11 DOWNTO 0) := "110010000000";  --X=25              or contents of location MNNN with TOS
constant op_XOR     : std_logic_vector(11 DOWNTO 0) := "110100000000";  --X=26              xor contents of location MNNN with TOS
constant op_CMP     : std_logic_vector(11 DOWNTO 0) := "110110000000";  --X=27                  compare contents of location MNNN against TOS
--constant op_FCMP    : std_logic_vector(11 DOWNTO 0) := "110110010000";  --X=27        | op_E    floating-point compare contents of location MNNN against TOS
--constant op_FADD    : std_logic_vector(11 DOWNTO 0) := "111000000000";  --X=28              floating-point add contents of location MNNN to TOS
--constant op_FSUB    : std_logic_vector(11 DOWNTO 0) := "111010000000";  --X=29              floating-point subtract contents of location MNNN from TOS
--constant op_FMUL    : std_logic_vector(11 DOWNTO 0) := "111100000000";  --X=30              floating-point multiply contents of location MNNN by TOS
constant op_FDIV    : std_logic_vector(11 DOWNTO 0) := "111110000000";  --X=31              floating-point divide contents of location MNNN by TOS
constant op_RTNCC   : std_logic_vector(11 DOWNTO 0) := "111111000000";  --X=23              return if condition is true
constant op_CALLCC  : std_logic_vector(11 DOWNTO 0) := "111111010000";  --X=23              call subroutine with address at PC+1 if condition is true
constant op_BRCC    : std_logic_vector(11 DOWNTO 0) := "111111100000";  --X=23              branch to address at PC+1 if condition is true
constant op_BRXCC   : std_logic_vector(11 DOWNTO 0) := "111111110000";  --X=23              branch to address at PC+1 if extended condition is true

--  CCR bits, partially decoded zero, other tests such as -1, -2, +1, even, odd, ... are possible
constant CCRbit_L      : integer := 0;     -- LSB, =1 if odd
constant CCRbit_N      : integer := 1;     -- MSB, =1 if negative
constant CCRbit_low0s  : integer := 2;     -- bits 1..5 are all zero
constant CCRbit_hgh0s  : integer := 3;     -- bits 6..10 are all zero
constant CCRbit_low1s  : integer := 4;     -- bits 1..5 are all one
constant CCRbit_hgh1s  : integer := 5;     -- bits 6..10 are all one
constant CCRbit_C      : integer := 6;     -- carry 
constant CCRbit_V      : integer := 7;     -- overflow
constant CCRhighend    : integer := 10;    -- high bit # for all zero or all ones high field
constant CCRhighst     : integer := 6;     -- low bit # for all zero or all ones high field
constant CCRlowend     : integer := 5;     -- high bit # for all zero or all ones low field
constant CCRlowst      : integer := 1;     -- low bit # for all zero or all ones low field

--  conditional instructions NNNv decode
constant CCRZ  : std_logic_vector(3 DOWNTO 0) := "0000";       -- also EQ
constant CCRNZ : std_logic_vector(3 DOWNTO 0) := "0001";       -- also NE
constant CCRCS : std_logic_vector(3 DOWNTO 0) := "0010";       -- also LO
constant CCRCC : std_logic_vector(3 DOWNTO 0) := "0011";       -- also HS
constant CCRMI : std_logic_vector(3 DOWNTO 0) := "0100";       -- MSB set
constant CCRPL : std_logic_vector(3 DOWNTO 0) := "0101";
constant CCROD : std_logic_vector(3 DOWNTO 0) := "0110";       -- LSB set
constant CCREV : std_logic_vector(3 DOWNTO 0) := "0111";
constant CCRVS : std_logic_vector(3 DOWNTO 0) := "1000";       -- overflow set
constant CCRVC : std_logic_vector(3 DOWNTO 0) := "1001";
constant CCRLE : std_logic_vector(3 DOWNTO 0) := "1010";       -- zero or (negative xor overflow)
constant CCRGT : std_logic_vector(3 DOWNTO 0) := "1011";       -- not(zero or (negative xor overflow))
constant CCRGE : std_logic_vector(3 DOWNTO 0) := "1100";       -- negative xor overflow
constant CCRLT : std_logic_vector(3 DOWNTO 0) := "1101";       -- not(negative xor overflow)
constant CCRLS : std_logic_vector(3 DOWNTO 0) := "1110";       -- carry or zero
constant CCRHI : std_logic_vector(3 DOWNTO 0) := "1111";       -- not(carry or zero)
--  extended conditional instructions
constant CCRNEG1      : std_logic_vector(3 DOWNTO 0) := "0000";       -- -1
constant CCRNNEG1     : std_logic_vector(3 DOWNTO 0) := "0001";
constant CCRONE       : std_logic_vector(3 DOWNTO 0) := "0010";       -- +1
constant CCRNONE      : std_logic_vector(3 DOWNTO 0) := "0011";
constant CCRSMIN      : std_logic_vector(3 DOWNTO 0) := "0100";       -- 0X800
constant CCRNSMIN     : std_logic_vector(3 DOWNTO 0) := "0101";
constant CCRSMAX      : std_logic_vector(3 DOWNTO 0) := "0110";       -- 0X7FF
constant CCRNSMAX     : std_logic_vector(3 DOWNTO 0) := "0111";
constant CCRNEG2      : std_logic_vector(3 DOWNTO 0) := "1000";       -- -2
constant CCRNNEG2     : std_logic_vector(3 DOWNTO 0) := "1001";
constant CCR0OR1      : std_logic_vector(3 DOWNTO 0) := "1010";       -- 0 or +1
constant CCRN0OR1     : std_logic_vector(3 DOWNTO 0) := "1011";
constant CCR0ORNEG1   : std_logic_vector(3 DOWNTO 0) := "1100";       -- 0 or -1
constant CCRN0ORNEG1  : std_logic_vector(3 DOWNTO 0) := "1101";
constant CCR01ORNEG1  : std_logic_vector(3 DOWNTO 0) := "1110";       -- 0 or +1 or -1
constant CCRN01ORNEG1 : std_logic_vector(3 DOWNTO 0) := "1111";

--  Not in use:
--constant op_SKPCC   : std_logic_vector(11 DOWNTO 0) := "101111000000";  --X=23              skip if condition is true

END constants;
