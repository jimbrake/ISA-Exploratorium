
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		James C Brakefield
-- 
-- Create Date:    12/05/2016 
-- Design Name:		LEM1_9stg 
-- Module Name:    constants - Behavioral 
-- Project Name:		LEM1_9
-- Target Devices: xilinx Artix-7 chip, Digilent CMOD A7 board
-- Tool versions:	 ISE 14.7
-- Description: 
--		Single bit data instructions to/from data RAM and accumulator.
--		Return address stack of 4+ addresses.
--		Supports 64-2048 word instruction ROM and 32 bits of data RAM.  IO mapped to data RAM locations.
--		Parameterization: return address stack depth (4-32), instruction address size (5-11) & data RAM size (16-32).  Shorter/smaller values reduce LUT counts.
-- Dependencies: 
--
-- Revision: 
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

--			Various constants for configuring memory and pointer sizes
constant inst_size     		: integer :=    9;	-- instructions are either 9 or 18 bits
constant prog_adr_size      : integer :=    8;	-- 2024x9 program memory max
constant prog_size          : integer :=  256;  -- 2024x9 program memory max
constant bitRAM_adr_size    : integer :=    5;	-- data memory address size, max is 5
constant bitRAM_size        : integer :=   32;  -- 32X1 data RAM max
constant rtn_stack_size		: integer :=    8;	-- 32x11 return stack memory max
constant rtn_ptr_size		: integer :=    3;	-- return stack memory pointer

--  		One word Op-codes                          XXXRPSSUU
constant op_LD		: std_logic_vector(8 downto 0) := "000000000";	-- mem(SS,UU) => A, push DS if P=1
constant op_LDC	    : std_logic_vector(8 downto 0) := "001000000";	-- not mem(SS,UU) => A, push DS if P=1
constant op_AND	    : std_logic_vector(8 downto 0) := "010000000";	-- A and mem(SS,UU) => A, push DS if P=1
constant op_OR		: std_logic_vector(8 downto 0) := "011000000";	-- A or mem(SS,UU) => A, push DS if P=1
constant op_XOR	    : std_logic_vector(8 downto 0) := "100000000";	-- A xor mem(SS,UU) => A, push DS if P=1
constant op_ADC	    : std_logic_vector(8 downto 0) := "101000000";	-- A + mem(SS,UU) + C => A, push DS if P=1, update C
constant op_ST		: std_logic_vector(8 downto 0) := "000100000";	-- A => mem(SS,UU), pop DS if P=1
constant op_STC	    : std_logic_vector(8 downto 0) := "001100000";	-- not A => mem(SS,UU), pop DS if P=1
constant op_RAND	: std_logic_vector(8 downto 0) := "010100000";	-- A and mem(SS,UU) => mem(SS,UU), pop DS if P=1
constant op_ROR	    : std_logic_vector(8 downto 0) := "011100000";	-- A or mem(SS,UU) => mem(SS,UU), pop DS if P=1
constant op_RXOR	: std_logic_vector(8 downto 0) := "100100000";	-- A xor mem(SS,UU) => mem(SS,UU), pop DS if P=1
constant op_RADC	: std_logic_vector(8 downto 0) := "101100000";	-- A + mem(SS,UU) + C => mem(SS,UU), pop DS if P=1, update C
constant op_INCM	: std_logic_vector(8 downto 0) := "110000000";	-- mem(SS,UU) + C => mem(SS,UU), update C
constant op_DECM	: std_logic_vector(8 downto 0) := "110100000";	-- '1' + mem(SS,UU) + C => mem(SS,UU), update C
constant op_MACS    : std_logic_vector(8 downto 0) := "111000000";	-- S & CC & AA (S:swap, CC & AA: nop,complement,0,1)
--  		Two word Op-codes                          1111XXXNN NNNNNNNN
constant op_CALL	: std_logic_vector(8 downto 0) := "111100000";	-- N => PC, RP - 1 => RP, PC+1 => mem(RP) 
constant op_JMP	    : std_logic_vector(8 downto 0) := "111100100";	-- N => PC
constant op_JAC	    : std_logic_vector(8 downto 0) := "111101000";	-- N => PC if A = 0, else PC + 1 => PC
constant op_JAS	    : std_logic_vector(8 downto 0) := "111101100";	-- N => PC if A = 1, else PC + 1 => PC
constant op_JCC	    : std_logic_vector(8 downto 0) := "111110000";	-- N => PC if C = 0, else PC + 1 => PC
constant op_JCS	    : std_logic_vector(8 downto 0) := "111110100";	-- N => PC if C = 1, else PC + 1 => PC
--			MACS Field modifiers								  1110SCCAA		Can S, CC & AA be OR'd together, includes base opcode
constant op_RTN     : std_logic_vector(8 downto 0) := "111000000";	-- mem(RP) => PC, RP + 1 => RP (replaces a null inst)
constant op_SWAP    : std_logic_vector(8 downto 0) := "111010000";	-- swap A and C, done after modifications to A & C
constant op_NOTA    : std_logic_vector(8 downto 0) := "111000001";	-- complement A
constant op_CLRA    : std_logic_vector(8 downto 0) := "111000010";	-- set A to zero
constant op_SETA    : std_logic_vector(8 downto 0) := "111000011";	-- set A to one
constant op_NOTC    : std_logic_vector(8 downto 0) := "111000100";	-- complement C
constant op_CLRC    : std_logic_vector(8 downto 0) := "111001000";	-- set C to zero
constant op_SETC    : std_logic_vector(8 downto 0) := "111001100";	-- set C to one
--constant op_XXX : std_logic_vector(8 downto 0) := "111011X1X";	-- redundant, can use for four additional op-codes

--function INCM(n: std_logic_vector(4 downto 0)) return std_logic_vector is 
--variable inst: std_logic_vector(8 downto 0);
--begin 	inst := op_INCM OR ("0000" & n);	return inst; end function INCM;

--function SETC() return std_logic_vector is
--variable inst: std_logic_vector(8 downto 0);
--begin 	inst := op_SCT1;	return inst; end function SETC;

--function JMP(n: std_logic_vector(10 downto 0)) return std_logic_vector is 
--variable inst: std_logic_vector(8 downto 0);
--begin 	inst := op_JMP OR ("0000000" & n(10 downto 9)); return inst; end function JMP;

--function JMP2(n: std_logic_vector(10 downto 0)) return std_logic_vector is 
--variable inst: std_logic_vector(8 downto 0);
--begin 	inst := n(8 downto 0); return inst; end function JMP2;

END constants;
