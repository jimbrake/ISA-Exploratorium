----------------------------------------------------------------------------------
-- Company:			Brakefield Research
-- Engineer:		James Brakefield
-- Create Date:		01/16/2025 
-- Design Name:		troc16_16 (16-bit data and 16-bit instructions)
-- Module Name:		constants
-- Project Name:	troc (typed register oriented computer)
-- Target Devices:	Spartan-7, zync ultrascale, artix-7. etc.  Vendor independent RTL
-- Tool versions:	Vivado 24.2
-- Description:		op-code & sizing constants
--	Op-code values shared between 16, 24 & 32 & 40 bit instructions
--	32x 16-bit, 64x 24-bit instructions, and 64x+ 32-bit instructions, 8-16-24-32 bit data sizes
--	initialy 16-bit data and 32-bit aligned instructions
--	Little endian
--	Special registers: $00 used for return address, $1E used for "residue: carry, overflow, mult MSH, divide remainder, etc.
-- Dependencies:	Derived from rios24_24
--
-- Additional Comments: 
--	Initial drop has only 16-bit instructions, 32-bit aligned instruction memory
--	32-bit ops given 00 suffix, allows zero op-code to be illegal instruction
--	16-bit instructions do not have memory load/store except for frame area that holds registers + tag bits
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

PACKAGE constantstag IS
--		Memory & register sizing
constant data_size          : integer :=   16;	-- also 8, 16 & 24 bit data sizes
constant tagdata_size       : integer :=   20;	-- two data type bits and two exponent bits
constant mem_adr_size       : integer :=   10;
constant mem_size           : integer := 1024;  -- 1024x16 program & data memory (half block RAM)
constant LUTRAM_adr_size    : integer :=    5;
constant LUTRAM_size        : integer :=   32;  -- tagged register file
constant LUTRAM_reg_size    : integer :=   32;  -- register size includes two "type" bits, additional mantissa & exponent bits

constant PCADR				: integer :=   31;	-- PC location in register File
constant RESADR				: integer :=   28;	-- residue register location in register File
constant FMADR				: integer :=   29;	-- frame pointer register (includes tagged register save/restore areas)
constant STKADR				: integer :=   30;	-- stack pointer register
--		Register names
constant PC_31		: unsigned(4 downto 0):= "11111";
constant Res_28		: unsigned(4 downto 0):= "11100";
constant R_0		: unsigned(4 downto 0):= "00000";
constant R_1		: unsigned(4 downto 0):= "00001";
constant R_2		: unsigned(4 downto 0):= "00010";
constant R_3		: unsigned(4 downto 0):= "00011";
constant R_4		: unsigned(4 downto 0):= "00100";
constant R_5		: unsigned(4 downto 0):= "00101";
constant R_6		: unsigned(4 downto 0):= "00110";
constant R_7		: unsigned(4 downto 0):= "00111";
constant R_8		: unsigned(4 downto 0):= "01000";
constant R_9		: unsigned(4 downto 0):= "01001";
constant R_10		: unsigned(4 downto 0):= "01010";
constant R_11		: unsigned(4 downto 0):= "01011";
constant R_12		: unsigned(4 downto 0):= "01100";
constant R_13		: unsigned(4 downto 0):= "01101";
constant R_14		: unsigned(4 downto 0):= "01110";
constant R_15		: unsigned(4 downto 0):= "01111";
constant R_16		: unsigned(4 downto 0):= "10000";
constant R_17		: unsigned(4 downto 0):= "10001";
constant R_18		: unsigned(4 downto 0):= "10010";
constant R_19		: unsigned(4 downto 0):= "10011";
constant R_20		: unsigned(4 downto 0):= "10100";
constant R_21		: unsigned(4 downto 0):= "10101";
constant R_22		: unsigned(4 downto 0):= "10110";
constant R_23		: unsigned(4 downto 0):= "10111";
constant R_24		: unsigned(4 downto 0):= "11000";
constant R_25		: unsigned(4 downto 0):= "11001";
constant R_26		: unsigned(4 downto 0):= "11010";
constant R_27		: unsigned(4 downto 0):= "11011";
constant R_28		: unsigned(4 downto 0):= "11100";
constant R_29		: unsigned(4 downto 0):= "11101";
constant R_30		: unsigned(4 downto 0):= "11110";
constant R_31		: unsigned(4 downto 0):= "11111";
--		Processing states
type state_type is (NORMst, Delyst, LDst, STst);  -- normal inst, two clock multiply, 2nd phase mem read, 2nd phase mem write
--type state_type is (NORMst, Delyst, LDUst, LDSst, LDFst, LDF2st, STst);  -- add states for various load type & store sizes

END constantstag;
