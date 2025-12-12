----------------------------------------------------------------------------------
-- Company:			Brakefield Research
-- Engineer:		James Brakefield
-- Create Date:		01/16/2025 
-- Design Name:		troc24 (8,16,24,32-bit data and 16,24,32-bit instructions)
-- Module Name:		opcodes
-- Project Name:	troc (typed register oriented computer)
-- Target Devices:	Spartan-7, zync ultrascale, artix-7. etc.  Vendor independent RTL
-- Tool versions:	Vivado 24.2
-- Description:		op-code constants for TROC24
--	(36) 16-bit, (44) 24-bit instructions, (44) 32-bit instructions, ? single operand functions
--	byte aligned data and instructions
--	Little endian
--  Special registers: $1C used for "residue: carry, overflow, mult MSH, divide remainder, etc.
--  Special registers: $1F used for program counter (current instruction address)
-- Dependencies:	Derived from rios24_24
--
-- Additional Comments: 
--	32-bit ops given 00 suffix, allows zero op-code to be illegal instruction byte
--	16-bit instructions do not have memory load/store except for absolute addressing
--	24-bit instructions sufficient for memory load/store/lea.  All 16-bit data size except 32-bit size for tagged ld/st
--	01/16/2025: cut & past from previous constants_231226.vhd
--	01/25/2025: corrected ennumeration of op-codes, spun out opcodes.vhd from constants.vhd
--	01/25/2025: for simplicity of op-code case statements, 16-bit has LSB=1,24-bit LSBs=10, 32-bit LSBs=00
--	02/19/2025: op16_LDTRN, STRN changed to op16_LDTN & STTN
--  05/05/2025: comment edits, 16-bit implementation uses half word addresssing (troc16_16...hwa)
--	05/09/2025: updates: drop LDT-STT, add AOB-SOB, overlay LDN-STN onto IN-OUT, overlay EXTRCT-INSRT onto SHFT-FUNC
--  05/09/2025: see TR16_423_ISA_250509.docx for further details; see ROCnn_32_250310.docx for ROC family architecture
--	05/16/2025: opcode prefixes changed to p1(trap bytes) p2(troc16 half-word) p3(troc16 24-bit ld/st instructions)
--	05/17/2025: op-codes & allocation per TR24_8234_ISA_250518.docx
--	05/17/2025: op-codes & allocation per TR16_4234_ISA_250604.docx (5) load/store FUNCTs
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

PACKAGE opcodes IS
--  	little endian addressing & instruction formating		
--		16-bit instructions:	sssss ddddd xxxx01   op(S,D) -> D	& nnnnn ddddd xxxx11 	op(imm,D) -> D
--		24-bit instructions:	rrrrr 0xx sssss ddddd xxxx10 		& nnnnn 1xx sssss ddddd xxxx10
--		32-bit instructions: ttttt xxx rrrrr 0xx sssss ddddd xxxx10 & nnnnn xxx rrrrr 1xx sssss ddddd xxxx10

--    16-bit immediate format:    n="10000" invokes next 16-bits as the signed immediate value
--    little n is R field, big N is following half-word, for TROC16 use absolute addressing with big N
--    24 & 32-bit instructions use -6..+7 or -2048..+2047 or three-four byte immediate value follows
constant p2IN		: unsigned(5 downto 0) := "000001";	-- IO port n => D
constant p2OUT		: unsigned(5 downto 0) := "001001";	-- D => IO port n
constant p2LD		: unsigned(5 downto 0) := "000001";	-- n="10000" next 16-bits are absolute memory address
constant p2ST		: unsigned(5 downto 0) := "001001";	-- n="10000" next 16-bits are absolute memory address
constant p2BSR		: unsigned(5 downto 0) := "010001";	-- PC+1,2 => D, PC+N => PC
constant p2MOV		: unsigned(5 downto 0) := "011001";	-- S => D
constant p2BRM		: unsigned(5 downto 0) := "111001";	-- PC+N => PC if MSB is 1
constant p2BRP		: unsigned(5 downto 0) := "110001";	-- PC+N => PC if MSB is 0
constant p2BRZ		: unsigned(5 downto 0) := "100001";	-- PC+N => PC if D is zero
constant p2BRNZ		: unsigned(5 downto 0) := "101001";	-- PC+N => PC if D is not zero

constant p2SHFT		: unsigned(5 downto 0) := "000011";	-- D << n => D (positive shifts are to the left)
constant p2EXTRCT	: unsigned(5 downto 0) := "000011";	-- n="10000" extract from D per N (uu0000wwww00mmmm) => residue
constant p2FUNCT	: unsigned(5 downto 0) := "001011";	-- Function n on D => D
constant p2INSRT	: unsigned(5 downto 0) := "001011";	-- n="10000" Insert residue into D per N (uu0000wwww00mmmm)
constant p2AOB		: unsigned(5 downto 0) := "010011";	-- PC+N => PC if D is not zero, increment D
constant p2SOB		: unsigned(5 downto 0) := "011011";	-- PC+N => PC if D is not zero, decrement D
constant p2LDI		: unsigned(5 downto 0) := "100011";	-- N as unsigned=> D
constant p2LDIS		: unsigned(5 downto 0) := "101011";	-- N as signed 	=> D
constant p2LDIF		: unsigned(5 downto 0) := "110011";	-- N as float 	=> D
constant p2LDIF2	: unsigned(5 downto 0) := "111011";	-- N as float2 	=> D

constant p2ADD		: unsigned(5 downto 0) := "000101";	-- S + D => D, carry/overflow/roundoff to residue
constant p2SUB		: unsigned(5 downto 0) := "001101";	-- S - D => D, carry/overflow/roundoff to residue
constant p2MUL		: unsigned(5 downto 0) := "010101";	-- S * D => D, upper half to residue/roundoff to residue
constant p2DIV		: unsigned(5 downto 0) := "011101";	-- D / S => D, remainder to residue
constant p2AND		: unsigned(5 downto 0) := "100101";	-- S and D => D
constant p2OR		: unsigned(5 downto 0) := "101101";	-- S or D  => D
constant p2XOR		: unsigned(5 downto 0) := "110101";	-- S xor D => D
constant p2CMP		: unsigned(5 downto 0) := "111101";	-- D - S comparison results => residue register

constant p2ADDI		: unsigned(5 downto 0) := "000111";	-- N + D => D, carry/overflow/roundoff to residue
constant p2SUBI		: unsigned(5 downto 0) := "001111";	-- N - D => D, carry/overflow/roundoff to residue
constant p2MULI		: unsigned(5 downto 0) := "010111";	-- N * D => D, upper half to residue/roundoff to residue
constant p2DIVI		: unsigned(5 downto 0) := "011111";	-- D / N => D, remainder to residue
constant p2ANDI		: unsigned(5 downto 0) := "100111";	-- N and D => D
constant p2ORI		: unsigned(5 downto 0) := "101111";	-- N or D => D
constant p2XORI		: unsigned(5 downto 0) := "110111";	-- N xor D => D
constant p2CMPI		: unsigned(5 downto 0) := "111111";	-- D - N comparison results => residue register

-- Single operand 16-bit instructons: Function S on D => D: p2f_xxxxx ddddd 001011 (p2_FUNC)
constant p2fSETUS	: unsigned(4 downto 0) := "00000";	-- set D to unsigned
constant p2fSETS	: unsigned(4 downto 0) := "00001";	-- set D to signed
constant p2fSETFLT	: unsigned(4 downto 0) := "00010";	-- set D to float
constant p2fSETFLT2	: unsigned(4 downto 0) := "00011";	-- set D to float2
constant p2fABS		: unsigned(4 downto 0) := "00100";	-- take absolute value of D
constant p2fNABS	: unsigned(4 downto 0) := "00101";	-- take negative absolute value of D
constant p2fTAG		: unsigned(4 downto 0) := "00110";	-- place D's tag bits into residue
constant p2fITAG	: unsigned(4 downto 0) := "00111";	-- place residue bits into D's tag
--                                            "010xx";  -- four empty slots
constant p2fLDUS	: unsigned(4 downto 0) := "01100";	-- Load residue with unsigned from M(D)
constant p2fLDS     : unsigned(4 downto 0) := "01101";	-- Load residue with signed from M(D)
constant p2fLDF     : unsigned(4 downto 0) := "01110";	-- Load residue with float from M(D)
constant p2fLDF2	: unsigned(4 downto 0) := "01111";	-- Load residue with float2 from M(D)
constant p2fST  	: unsigned(4 downto 0) := "10001";	-- convert and store Residue to M(D)
--                                            "10xxx";  -- six empty slots
--                                            "110xx";  -- four empty slots
constant p2fCVTUS	: unsigned(4 downto 0) := "11100";	-- convert D to unsigned
constant p2fCVTS	: unsigned(4 downto 0) := "11101";	-- convert D to signed
constant p2fCVTFLT	: unsigned(4 downto 0) := "11110";	-- convert D to float
constant p2fCVTFLT2	: unsigned(4 downto 0) := "11111";	-- convert D to float2

--		**** 24-bit ops
-- Load/Store instructions 
constant p3LD8U		: unsigned(7 downto 0) := "10000010";	-- Unsigned mem(S + R,N)   => D
constant p3LD16U	: unsigned(7 downto 0) := "10000110";	-- Unsigned mem(S + 2*R,N) => D
constant p3LD24U	: unsigned(7 downto 0) := "10001010";	-- Unsigned mem(S + 3*R,N) => D
constant p3LD32U	: unsigned(7 downto 0) := "10001110";	-- Unsigned mem(S + 4*R,N) => D
constant p3LD8S		: unsigned(7 downto 0) := "10010010";	-- Signed   mem(S + R,N)   => D
constant p3LD16S	: unsigned(7 downto 0) := "10010110";	-- Signed   mem(S + 2*R,N) => D
constant p3LD24S	: unsigned(7 downto 0) := "10011010";	-- Signed   mem(S + 3*R,N) => D
constant p3LD32S	: unsigned(7 downto 0) := "10011110";	-- Signed   mem(S + 4*R,N) => D
constant p3LD8F		: unsigned(7 downto 0) := "10100010";	-- Float    mem(S + R,N)   => D
constant p3LD16F	: unsigned(7 downto 0) := "10100110";	-- Float    mem(S + 2*R,N) => D
constant p3LD24F	: unsigned(7 downto 0) := "10101010";	-- Float    mem(S + 3*R,N) => D
constant p3LD32F	: unsigned(7 downto 0) := "10101110";	-- Float    mem(S + 4*R,N) => D
constant p3LD8F2	: unsigned(7 downto 0) := "10110010";	-- Float2   mem(S + R,N)   => D
constant p3LD16F2	: unsigned(7 downto 0) := "10110110";	-- Float2   mem(S + 2*R,N) => D
constant p3LD24F2	: unsigned(7 downto 0) := "10111010";	-- Float2   mem(S + 3*R,N) => D
constant p3LD32F2	: unsigned(7 downto 0) := "10111110";	-- Float2   mem(S + 4*R,N) => D
constant p3ST8		: unsigned(7 downto 0) := "01000010";	-- D => mem(S + R,I)
constant p3ST16		: unsigned(7 downto 0) := "01000110";	-- D => mem(S + 2*R,I)
constant p3ST24		: unsigned(7 downto 0) := "01001010";	-- D => mem(S + 3*R,I) 
constant p3ST32		: unsigned(7 downto 0) := "01001110";	-- D => mem(S + 4*R,I) 
--constant p3			: unsigned(7 downto 0) := "01 010010";	-- empty slot, was p3LEA8
--constant p3			: unsigned(7 downto 0) := "01 010110";	-- empty slot, was p3LEA16
--constant p3			: unsigned(7 downto 0) := "01 011010";	-- empty slot, was p3LEA24
--constant p3			: unsigned(7 downto 0) := "01 011110";	-- empty slot, was p3LEA32
-- ALU instructions
constant p3ADD		: unsigned(7 downto 0) := "01100010";	-- R,I + S => D, carry/overflow/roundoff to residue
constant p3SUB		: unsigned(7 downto 0) := "01100110";	-- R,I - S => D, carry/overflow/roundoff to residue
constant p3MUL		: unsigned(7 downto 0) := "01101010";	-- R,I * S => D, upper half to residue/roundoff to residue
constant p3DIV		: unsigned(7 downto 0) := "01101110";	-- S / R,I => D, remainder to residue
constant p3AND		: unsigned(7 downto 0) := "01110010";	-- S and R,I => D
constant p3OR		: unsigned(7 downto 0) := "01110110";	-- S or R,I  => D
constant p3XOR		: unsigned(7 downto 0) := "01111010";	-- S xor R,I => D
constant p3CMP		: unsigned(7 downto 0) := "01111110";	-- S - R,I comparison results => residue register
-- MISC instructions
constant p3EXTRCT	: unsigned(7 downto 0) := "00000010";	-- Extract field from S => D per R,I(width & start bit)
constant p3INSRT	: unsigned(7 downto 0) := "00000110";	-- 
constant p3SHL		: unsigned(7 downto 0) := "00001010";	-- Shift S left => D per signed shift count in R,I
constant p3MAX		: unsigned(7 downto 0) := "00001110";	-- MAX of R,I and S => D
constant p3MIN		: unsigned(7 downto 0) := "00010010";	-- MIN of R,I and S => D
constant p3FUNC		: unsigned(7 downto 0) := "00010110";	-- Function R,I on S => D
constant p3INTP		: unsigned(7 downto 0) := "00011010";	-- Interpolate/blend
constant p3CMOV		: unsigned(7 downto 0) := "00011110";	-- If S=0 R,I => D
-- Conditional instructions
constant p3JMPcc	: unsigned(7 downto 0) := "00100010";	-- Jump to location R,I if conditon on S matches D
constant p3BRcc		: unsigned(7 downto 0) := "00100110";	-- Branch to location PC+R,I if conditon on S matches D
constant p3BBS0		: unsigned(7 downto 0) := "00101010";	-- Branch relative bit set on bit 0&D of S 
constant p3BBS1		: unsigned(7 downto 0) := "00101110";	-- Branch relative bit set on bit 1&D of S (bits 32..63)
constant p3BBC0		: unsigned(7 downto 0) := "00110010";	-- Branch relative bit clear on bit 0&D of S
constant p3BBC1		: unsigned(7 downto 0) := "00110110";	-- Branch relative bit clear on bit 1&D of S
--constant p3			: unsigned(7 downto 0) := "00 111010";	-- empty slot
constant p3CASE		: unsigned(7 downto 0) := "00111110";	-- Limit at R,I index at S base at D: Mem24(3*S+D)=>PC

--		**** 32-bit ops 
-- Soft and hard traps     use 8-bit byte at M(PC), a 32-bit instruction of with six LSB zero
constant p1ALGC	: unsigned(7 downto 0) := "11000000";	-- cache or memory block align
constant p1ALGN	: unsigned(7 downto 0) := "10000000";	-- word align (typically 32-bit align)
constant p1BKPT	: unsigned(7 downto 0) := "01000000";	-- Breakpoint, PC => Interrupt IO register
constant p1TRAP	: unsigned(7 downto 0) := "00000000";	-- Trap/Hard error, PC => Interrupt IO register
-- Load/Store instructions
constant p4LD8U		: unsigned(7 downto 0) := "10000000";	-- Unsigned mem(S+R*GS+T,N)  =>D
constant p4LD16U	: unsigned(7 downto 0) := "10000100";	-- Unsigned mem(S+2*R*GS+T,N)=>D
constant p4LD24U	: unsigned(7 downto 0) := "10001000";	-- Unsigned mem(S+3*R*GS+T,N)=>D
constant p4LD32U	: unsigned(7 downto 0) := "10001100";	-- Unsigned mem(S+4*R*GS+T,N)=>D
constant p4LD8S		: unsigned(7 downto 0) := "10010000";	-- Signed   mem(S+R*GS+T,N)  =>D
constant p4LD16S	: unsigned(7 downto 0) := "10010100";	-- Signed   mem(S+2*R*GS+T,N)=>D
constant p4LD24S	: unsigned(7 downto 0) := "10011000";	-- Signed   mem(S+3*R*GS+T,N)=>D
constant p4LD32S	: unsigned(7 downto 0) := "10011100";	-- Signed   mem(S+4*R*GS+T,N)=>D
constant p4LD8F		: unsigned(7 downto 0) := "10100000";	-- Float    mem(S+R*GS+T,N)  =>D
constant p4LD16F	: unsigned(7 downto 0) := "10100100";	-- Float    mem(S+2*R*GS+T,N)=>D
constant p4LD24F	: unsigned(7 downto 0) := "10101000";	-- Float    mem(S+3*R*GS+T,N)=>D
constant p4LD32F	: unsigned(7 downto 0) := "10101100";	-- Float    mem(S+4*R*GS+T,N)=>D
constant p4LD8F2	: unsigned(7 downto 0) := "10110000";	-- Float2   mem(S+R*GS+T,N)  =>D
constant p4LD16F2	: unsigned(7 downto 0) := "10110100";	-- Float2   mem(S+2*R*GS+T,N)=>D
constant p4LD24F2	: unsigned(7 downto 0) := "10111000";	-- Float2   mem(S+3*R*GS+T,N)=>D
constant p4LD32F2	: unsigned(7 downto 0) := "10111100";	-- Float2   mem(S+4*R*GS+T,N)=>D
constant p4ST8		: unsigned(7 downto 0) := "01000000";	-- D => mem(S + R*GS,N)
constant p4ST16		: unsigned(7 downto 0) := "01000100";	-- D => mem(S + 2*R*GS,N)
constant p4ST24		: unsigned(7 downto 0) := "01001000";	-- D => mem(S + 3*R*GS,N) 
constant p4ST32		: unsigned(7 downto 0) := "01001100";	-- D => mem(S + 4*R*GS,N) 
--constant p4			: unsigned(7 downto 0) := "01 010000";	-- empty slot, was p4LEA8
--constant p4			: unsigned(7 downto 0) := "01 010100";	-- empty slot, was p4LEA16
--constant p4			: unsigned(7 downto 0) := "01 011000";	-- empty slot, was p4LEA24
--constant p4			: unsigned(7 downto 0) := "01 011100";	-- empty slot, was p4LEA32
-- ALU instructons
constant p4ADD		: unsigned(7 downto 0) := "01100000";	-- T,I+R+S => D, carry/overflow/roundoff to residue
constant p4SUB		: unsigned(7 downto 0) := "01100100";	-- T,I+R-S => D, carry/overflow/roundoff to residue
constant p4MAC		: unsigned(7 downto 0) := "01101000";	-- T,I*S+R => D, upper half to residue/roundoff to residue
constant p4DIV		: unsigned(7 downto 0) := "01101100";	-- S / R&T,I => D, remainder to residue
constant p4AND		: unsigned(7 downto 0) := "01110000";	-- S and R ans T,I => D
constant p4OR		: unsigned(7 downto 0) := "01110100";	-- S or R or T,I  => D
constant p4XOR		: unsigned(7 downto 0) := "01111000";	-- S xor R xor T,I => D
constant p4CMP		: unsigned(7 downto 0) := "01111100";	-- S - R,I comparison results => residue register
-- MISC instructions
--constant p4TRAP		: unsigned(7 downto 0) := "00 000000";	-- The P1 instructions
constant p4INSRT	: unsigned(7 downto 0) := "00000100";	-- Insert LSB bits of R into S per T,I; results => D
constant p4SHL		: unsigned(7 downto 0) := "00001000";	-- Shift R&S left => D per signed shift count in T,I
constant p4MAX		: unsigned(7 downto 0) := "00001100";	-- MAX of T,I and R and S  => D
constant p4MIN		: unsigned(7 downto 0) := "00010000";	-- MIN of T,I and R and S => D
constant p4FUNC		: unsigned(7 downto 0) := "00010100";	-- Median of T,I and R and S => D
constant p4INTP		: unsigned(7 downto 0) := "00011000";	-- Interpolate/blend
constant p4CMOV		: unsigned(7 downto 0) := "00011100";	-- If S=0 T,I => D else R => D 
-- Conditional & misc instructions
constant p4JMPcc	: unsigned(7 downto 0) := "00100000";	-- Jump to location N if conditon on S matches D
constant p4BRcc		: unsigned(7 downto 0) := "00100100";	-- Branch to location PC+R,I if conditon on D matches S
constant p4VECT		: unsigned(7 downto 0) := "00101000";	-- Identify loop registers
constant p4LOOP		: unsigned(7 downto 0) := "00101100";	-- Mark top of loop
constant p4MISC		: unsigned(7 downto 0) := "00110000";	-- MMOV, PCND, PCB1, STM, LDM, MUX via 3 op bits
constant p4P3OPS	: unsigned(7 downto 0) := "00110100";	-- 24-bit instructions with 3 more op-bits per S
constant p4MANI		: unsigned(7 downto 0) := "00111000";	-- Insert mantissa? 
constant p4CASE		: unsigned(7 downto 0) := "00111100";	-- Table base reg; index; T,I limit; PC base; eight modes

END opcodes;
