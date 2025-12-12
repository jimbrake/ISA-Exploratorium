----------------------------------------------------------------------------------
-- Company: 	Brakefield Research
-- Engineer: 	James Brakefield
-- 
-- Create Date:	20:46:00 01/31/2016 
-- Design Name:	rois24_3sz 
-- Module Name: constants - Behavioral 
-- Project Name:	rois24_3szmin
-- Target Devices:	Spartan-7, Boolean Board
-- Tool versions: 	Vivado 25.1
-- Description:	Op-code constants & register sizing
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--	7/12/2025	reworked into little endian and hexidecimal
-- Additional Comments: 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;

PACKAGE constants IS

--function fmt_inst(op, d, r, s: std_logic_vector(5 downto 0)) return std_logic_vector is -- concatenate 24-bit instruction
--variable inst: std_logic_vector(23 downto 0);
--begin
--inst := op & d & r & s;
--return inst;
--end function fmt_inst;

constant data_size          : integer :=   24;
constant mem_adr_size       : integer :=    9;
constant mem_size           : integer :=  512;  -- 512x16x2 program memory 
constant LUTRAM_adr_size    : integer :=    5;
constant LUTRAM_size        : integer :=   32;  -- 64X24 register file

type blkRAM_type is array(mem_size-1 downto 0) of unsigned(7 downto 0);    -- block RAM array type
type state_type is (NORMst, LDst, LDBst, LDHst, LDSBst, LDSHst, STst);     -- normal inst, 2nd phase mem reads, 2nd phase mem write

-- For R = 0 or S = 0: the operand is zero rather than register 0 (via never writing to register 0 & all regs init'd to zero)
-- Prefix register loaded with 18-bit value by op_PFX, concatenated in front of N on next N/I or sNN instruction
-- Three register instructions use "1xxxxx" codes
-- 6-bit immediate instructions use "x1xxxx" codes
-- 12 & 18-bit immediate instructions use "00xxxx" codes
--  		two operand Op-codes                                   RRRRRR SSSSSS DDDDDD XXXXXX
constant op_ADD		: unsigned(5 downto 0) := "100000";	-- R + S => D
constant op_SUB		: unsigned(5 downto 0) := "100001";	-- R - S => D
constant op_ADC		: unsigned(5 downto 0) := "100010";	-- R + S + carry => D
constant op_SBC		: unsigned(5 downto 0) := "100011";	-- R - S + carry => D
constant op_AND		: unsigned(5 downto 0) := "100100";	-- R and S => D
constant op_ANDC	: unsigned(5 downto 0) := "100101";	-- R and not S => D
constant op_OR		: unsigned(5 downto 0) := "100110";	-- R or S => D
constant op_XOR		: unsigned(5 downto 0) := "100111";	-- R xor S => D
constant op_MUL	    : unsigned(5 downto 0) := "101000";	-- R * S => D
constant op_MULU    : unsigned(5 downto 0) := "101001";	-- (R * S)>>24 => D
constant op_MULUS	: unsigned(5 downto 0) := "101010";	-- (R * S)>>24 => D
constant op_DIV  	: unsigned(5 downto 0) := "101011";	-- start DR/S (not implemented)
constant op_FADD	: unsigned(5 downto 0) := "101100";	-- R + S => D (not implemented)
constant op_FSUB	: unsigned(5 downto 0) := "101101";	-- R - S => D (not implemented)
constant op_FMUL	: unsigned(5 downto 0) := "101110";	-- R * S => D (not implemented)
constant op_FDIV	: unsigned(5 downto 0) := "101111";	-- R / S => D (not implemented)
--		indexed addressing		                                   RRRRRR SSSSSS DDDDDD XXXXXX
constant op_LD		: unsigned(5 downto 0) := "011101";	-- mem(R + 3*S) => D
constant op_ST		: unsigned(5 downto 0) := "011111";	-- D => mem(R + 3*S)
constant op_LDF		: unsigned(5 downto 0) := "001110";	-- mem(R + 3*S) => D
constant op_STF		: unsigned(5 downto 0) := "001111";	-- D => mem(R + 3*S)
constant op_CALL	: unsigned(5 downto 0) := "000110";	-- branch to R + S, PC+1 => D
constant op_JMPCC	: unsigned(5 downto 0) := "000001";	-- if condition D true branch to R + S
constant op_LDB		: unsigned(5 downto 0) := "011000";	-- mem(R + S) => D
constant op_STB		: unsigned(5 downto 0) := "011001";	-- D => mem(R + S)
constant op_LDH		: unsigned(5 downto 0) := "011010";	-- mem(R + S) => D
constant op_STH		: unsigned(5 downto 0) := "011011";	-- D => mem(R + S)
constant op_LDSB	: unsigned(5 downto 0) := "011100";	-- sign extended mem(R + S) => D
constant op_LDSH    : unsigned(5 downto 0) := "011110";	-- sign extended mem(R + S) => D
--  	6-bit immediate Op-codes                                   NNNNNN SSSSSS 0CCCCC XXXXXX
constant op_ADDI	: unsigned(5 downto 0) := "110000";	-- R + N => D
constant op_SUBI	: unsigned(5 downto 0) := "110001";	-- R - N => D
constant op_ADCI	: unsigned(5 downto 0) := "110010";	-- R + N + carry => D
constant op_SBCI	: unsigned(5 downto 0) := "110011";	-- R - N + carry => D
constant op_ANDI	: unsigned(5 downto 0) := "110100";	-- R and N => D
constant op_ANDCI	: unsigned(5 downto 0) := "110101";	-- R and not N => D
constant op_ORI		: unsigned(5 downto 0) := "110110";	-- R or N => D
constant op_XORI	: unsigned(5 downto 0) := "110111";	-- R xor N => D
constant op_MULI	: unsigned(5 downto 0) := "111000";	-- R * N => D (not implemented)
constant op_MULUI	: unsigned(5 downto 0) := "111001";	-- (R * N)>>24 => D (not implemented)
constant op_MULUSI  : unsigned(5 downto 0) := "111010";	-- (R * N)>>24 => D (signed)(not implemented)
constant op_DIVI	: unsigned(5 downto 0) := "111011";	-- start DR/N (not implemented)
constant op_FADDI	: unsigned(5 downto 0) := "111100";	-- R + N => D (not implemented)
constant op_FSUBI	: unsigned(5 downto 0) := "111101";	-- R - N => D (not implemented)
constant op_FMULI	: unsigned(5 downto 0) := "111110";	-- R * N => D (not implemented)
constant op_FDIVI	: unsigned(5 downto 0) := "111111";	-- R / N => D (not implemented)
--		S + N addressing		                                   sNNNNN SSSSSS DDDDDD XXXXXX
constant op_LDN	    : unsigned(5 downto 0) := "011000";	-- mem(S + N) => D
constant op_STN	    : unsigned(5 downto 0) := "011001";	-- D => mem(S + N)
constant op_LDFN	: unsigned(5 downto 0) := "001100";	-- mem(S + N) => D
constant op_STFN	: unsigned(5 downto 0) := "001101";	-- D => mem(S + N)
constant op_LDBN	: unsigned(5 downto 0) := "010000";	-- mem(S + N) => D
constant op_STBN	: unsigned(5 downto 0) := "010001";	-- D => mem(S + N)
constant op_LDHN	: unsigned(5 downto 0) := "010010";	-- mem(S + N) => D
constant op_STHN	: unsigned(5 downto 0) := "010011";	-- D => mem(S + N)
constant op_LDSBN	: unsigned(5 downto 0) := "010100";	--  sign extendedmem(S + N) => D
constant op_LDSHN   : unsigned(5 downto 0) := "010101";	--  sign extendedmem(S + N) => D
constant op_CALLN	: unsigned(5 downto 0) := "000100";	-- branch to S + N, PC+1 => D
constant op_INN	    : unsigned(5 downto 0) := "001010";	-- Input port S+N => D
constant op_OUTN 	: unsigned(5 downto 0) := "001011";	-- D => output port S+N
--  	12-bit immediate Op-codes                                  sNNNNN NNNNNN DDDDDD XXXXXX
constant op_CALLR	: unsigned(5 downto 0) := "000101";	-- branch to PC+sNN, PC+1 => D
constant op_BRCC	: unsigned(5 downto 0) := "000010";	-- if condition D true branch to PC+sNN
constant op_JMPccN	: unsigned(5 downto 0) := "000011";	-- if condition D true branch to PC+sNN
constant op_LDSI	: unsigned(5 downto 0) := "001000";	-- sNN => D
constant op_JMPCC	: unsigned(5 downto 0) := "000001";	-- if condition D true branch to sNN
--      18-bit immediate Op-code                                   NNNNNN NNNNNN NNNNNN XXXXXX
constant op_PFX		: unsigned(5 downto 0) := "001001";	-- NNN => prefix reg (concatenates with next sN or sNN or sNNN)
constant op_TRAP	: unsigned(5 downto 0) := "000000";	-- illegal instruction trap, also BKPT, ALGN, ALGC

--constant op_JMPN	: unsigned(5 downto 0) := "011010";	-- branch to S + N      (see CALLN)       convenience op-code, D=0
--constant op_BR  	: unsigned(5 downto 0) := "000100";	-- call to PC+sNN (HLT if sNN=0, NOP if sNN=1) convenience op-code, D=0
--constant op_HLT	    : unsigned(23 downto 0):= "000100000000000000000000";	-- branch relative to self convenience op-code, D=0

--          condition codes, always located in the D register field
--	uncompressed CCR is signs of the two adder inputs and sign of result, carry out & 24-bit ALU result
--	compressed CCR is overflow, carry, MSB, exp all 1s, exp all 0s, mant all 1s, mant all 0s, LSB
--  Boolean instructions do not change carry or overflow but do change MSB
--constant cc_A		: unsigned(5 downto 0) := "000000";	-- always true
--constant cc_NOP		: unsigned(5 downto 0) := "000001";	-- always false
constant cc_Z   	: unsigned(5 downto 0) := "000010";	-- true if result zero
constant cc_NZ   	: unsigned(5 downto 0) := "000011";	-- true if result not zero
constant cc_CS   	: unsigned(5 downto 0) := "000100";	-- true if result carry set
constant cc_CC   	: unsigned(5 downto 0) := "000101";	-- true if result carry clear
constant cc_MI   	: unsigned(5 downto 0) := "000110";	-- true if result MSB set
constant cc_PL   	: unsigned(5 downto 0) := "000111";	-- true if result MSB clear
constant cc_VS   	: unsigned(5 downto 0) := "001000";	-- true if signed overflow
constant cc_VC   	: unsigned(5 downto 0) := "001001";	-- true if no signed overflow
constant cc_LE   	: unsigned(5 downto 0) := "001010";	-- true if result less than or equal
constant cc_GT   	: unsigned(5 downto 0) := "001011";	-- true if result greater than
constant cc_GE   	: unsigned(5 downto 0) := "001100";	-- true if result greater than or equal
constant cc_LT   	: unsigned(5 downto 0) := "001101";	-- true if result less than
constant cc_LS   	: unsigned(5 downto 0) := "001110";	-- true if unsigned result low or same
constant cc_HI  	: unsigned(5 downto 0) := "001111";	-- true if unsigned result high
--	non-traditional condition codes
constant cc_OD   	: unsigned(5 downto 0) := "010000";	-- true if result LSB set
constant cc_EV   	: unsigned(5 downto 0) := "010001";	-- true if result LSB clear
constant cc_1   	: unsigned(5 downto 0) := "010010";	-- true if result = 1
constant cc_N1   	: unsigned(5 downto 0) := "010011";	-- true if result not = 1
constant cc_M1   	: unsigned(5 downto 0) := "010100";	-- true if result = -1
constant cc_NM1   	: unsigned(5 downto 0) := "010101";	-- true if result not = -1
constant cc_M2   	: unsigned(5 downto 0) := "010110";	-- true if result = -2
constant cc_NM2   	: unsigned(5 downto 0) := "010111";	-- true if result not = -2
constant cc_01   	: unsigned(5 downto 0) := "011000";	-- true if result = zero or one
constant cc_N01   	: unsigned(5 downto 0) := "011001";	-- true if result not = zero or one
constant cc_0M1   	: unsigned(5 downto 0) := "011010";	-- true if result = zero or negative one
constant cc_N0M1   	: unsigned(5 downto 0) := "011011";	-- true if result not = zero or negative one
constant cc_01M1   	: unsigned(5 downto 0) := "011100";	-- true if result = zero, one or negative one
constant cc_N01M1  	: unsigned(5 downto 0) := "011101";	-- true if result not = zero, one or negative one
constant cc_01M12  	: unsigned(5 downto 0) := "011110";	-- true if result = zero, one, negative one or negative 2
constant cc_N01M12	: unsigned(5 downto 0) := "011111";	-- true if result not = zero, one, negative one or negative 2
--	alternate condition code names
constant cc_EQ   	: unsigned(5 downto 0) := "000010";	-- true if result equal                 (same encoding as cc_Z)
constant cc_NE   	: unsigned(5 downto 0) := "000011";	-- true if result not equal             (same encoding as cc_NZ)
constant cc_LO   	: unsigned(5 downto 0) := "000100";	-- true if unsigned result low          (same encoding as cc_CS)
constant cc_HS   	: unsigned(5 downto 0) := "000101";	-- true if unsigned result high or same (same encoding as cc_CC)

END constants;
