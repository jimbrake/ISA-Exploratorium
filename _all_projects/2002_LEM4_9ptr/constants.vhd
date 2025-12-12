----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		James C Brakefield
-- 
-- Create Date:    01/03/2017 
-- Design Name:		LEM4_9ptr 
-- Module Name:    constants - Behavioral 
-- Project Name:		LEM4_9ptr
-- Target Devices: xilinx Artix-7 chip, Digilent CMOD A7 board
-- Tool versions:	 ISE 14.7
-- Description: 
--		Single digit at a time instructions to/from top data RAM.
--		Data pointer RAM has four data pointers AKA index registers.  Return address stack of 4+ addresses.
--		Supports 64-2048 word instruction ROM and 32-512 digits of data RAM.  IO mapped to data RAM locations.
--		Parameterization: return address stack depth (4-32), instruction address size (6-11) &
--		 data RAM size (32-512).  Shorter/smaller values reduce LUT counts.
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created from LEM1_9ptr
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
constant digitRAM_adr_size  : integer :=    6;	-- data memory address size, max is 9
constant digitRAM_size      : integer :=   64;  -- 512X1 data RAM max, includes data stack area
constant rtn_stack_size		: integer :=    8;	-- 32x11 return stack memory max
constant rtn_ptr_size		: integer :=    3;	-- return stack memory pointer
constant digit_size         : integer :=    4;  -- to get rid of naked numbers
--in addition LUT RAM used to hold three data memory pointers of bitRAM_adr_size
--if only used as accumulator machine(P bit always zero), then no data stack pointer register

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
constant op_JAZ	    : std_logic_vector(8 downto 0) := "111101000";	-- N => PC if A = 0, else PC + 1 => PC
constant op_JANZ    : std_logic_vector(8 downto 0) := "111101100";	-- N => PC if A = 1, else PC + 1 => PC
constant op_JCC	    : std_logic_vector(8 downto 0) := "111110000";	-- N => PC if C = 0, else PC + 1 => PC
constant op_JCS	    : std_logic_vector(8 downto 0) := "111110100";	-- N => PC if C = 1, else PC + 1 => PC
constant op_LDPT    : std_logic_vector(8 downto 0) := "111111000";	-- N => PTn, if n=0 load data/stack pointer
constant op_ADPT    : std_logic_vector(8 downto 0) := "111111100";	-- PTn + N => PTn if n=0 adjust data/stack pointer
--			Index Field modifiers					   XXXRP11UU NNNNNNNN
constant idx_DX	    : std_logic_vector(8 downto 0) := "000000000";	-- mem(UU)
constant idx_PP	    : std_logic_vector(8 downto 0) := "000000100";	-- mem(UU), UU + 1 => UU
constant idx_MM	    : std_logic_vector(8 downto 0) := "000001000";	-- UU - 1 => UU, mem(UU)
constant idx_OF	    : std_logic_vector(8 downto 0) := "000001100";	-- mem(UU + N)
--			Pointer register numbers and pointer indirect
constant ptr_0			 : std_logic_vector(8 downto 0) := "000000000";
constant ptr_1			 : std_logic_vector(8 downto 0) := "000000001";
constant ptr_2			 : std_logic_vector(8 downto 0) := "000000010";
constant ptr_3			 : std_logic_vector(8 downto 0) := "000000011";
--			Pointer register numbers and pointer indirect with post increment
constant ptr_0PP		 : std_logic_vector(8 downto 0) := "000000100";
constant ptr_1PP		 : std_logic_vector(8 downto 0) := "000000101";
constant ptr_2PP		 : std_logic_vector(8 downto 0) := "000000110";
constant ptr_3PP		 : std_logic_vector(8 downto 0) := "000000111";
--			Pointer register numbers and pointer indirect with pre decrement
constant ptr_0MM		 : std_logic_vector(8 downto 0) := "000001000";
constant ptr_1MM		 : std_logic_vector(8 downto 0) := "000001001";
constant ptr_2MM		 : std_logic_vector(8 downto 0) := "000001010";
constant ptr_3MM		 : std_logic_vector(8 downto 0) := "000001011";
--			Pointer register numbers and pointer indirect with offset
constant ptr_0OF		 : std_logic_vector(8 downto 0) := "000001100";
constant ptr_1OF		 : std_logic_vector(8 downto 0) := "000001101";
constant ptr_2OF		 : std_logic_vector(8 downto 0) := "000001110";
constant ptr_3OF		 : std_logic_vector(8 downto 0) := "000001111";
--			MACS Field modifiers		11100NNNN 111010ACC 111011XXX	include base opcode
constant op_INTA    : std_logic_vector(8 downto 0) := "111000000";	-- set A to NNNN
constant op_RTN     : std_logic_vector(8 downto 0) := "111010000";	-- return: mem(RP) => PC, RP + 1 => RP
constant op_CMPA    : std_logic_vector(8 downto 0) := "111010100";	-- complement A
constant op_NOTC    : std_logic_vector(8 downto 0) := "111010001";	-- complement C
constant op_CLRC    : std_logic_vector(8 downto 0) := "111010010";	-- set C to zero
constant op_SETC    : std_logic_vector(8 downto 0) := "111010011";	-- set C to one
constant op_BIN     : std_logic_vector(8 downto 0) := "111011000";	-- set binary digit add
constant op_BCD     : std_logic_vector(8 downto 0) := "111011001";	-- set BCD digit add
constant op_ASL     : std_logic_vector(8 downto 0) := "111011010";	-- arithmetic shift leftS
constant op_ASR     : std_logic_vector(8 downto 0) := "111011011";	-- arithmetic shift right
constant op_RLA     : std_logic_vector(8 downto 0) := "111011100";	-- rotate A left
constant op_RRA     : std_logic_vector(8 downto 0) := "111011101";	-- rotate A right
constant op_RLAC    : std_logic_vector(8 downto 0) := "111011110";	-- rotate A & C left
constant op_RRAC    : std_logic_vector(8 downto 0) := "111011111";	-- rotate A & C right

END constants;
