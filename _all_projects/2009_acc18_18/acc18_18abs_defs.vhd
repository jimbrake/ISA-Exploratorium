-- acc18_18abs_defs.vhd
-- type declarations & constants
-- instruction format is 4:CC, 5:op-code, 9: absolute address
-- skip allways are 7:"0111xxx", 11: absolute address

library IEEE;
use IEEE.std_logic_1164.all;

package definitions is

-- machine instructions memonics sorted by code & sub-code
--  ir(12..9) op-codes
constant opLD:   std_logic_vector(4 downto 0) :="00000";
constant opLDC:  std_logic_vector(4 downto 0) :="00001";
constant opADD:  std_logic_vector(4 downto 0) :="00010";
constant opADC:  std_logic_vector(4 downto 0) :="00011";
constant opSUB:  std_logic_vector(4 downto 0) :="00100";
constant opSBC:  std_logic_vector(4 downto 0) :="00101";
constant opAND:  std_logic_vector(4 downto 0) :="00110";
constant opOR:   std_logic_vector(4 downto 0) :="00111";
constant opXOR:  std_logic_vector(4 downto 0) :="01000";
constant opCMP:  std_logic_vector(4 downto 0) :="01001";
constant opBIT:  std_logic_vector(4 downto 0) :="01010";
constant opST:   std_logic_vector(4 downto 0) :="01011";
constant opMUL:  std_logic_vector(4 downto 0) :="01100";
constant opINC:  std_logic_vector(4 downto 0) :="01101";
constant opDEC:  std_logic_vector(4 downto 0) :="01110";
constant opCLR:  std_logic_vector(4 downto 0) :="01111";
constant opLDI:  std_logic_vector(4 downto 0) :="10000";
constant opLDIU: std_logic_vector(4 downto 0) :="10001";
constant opADDI: std_logic_vector(4 downto 0) :="10010";
constant opADCI: std_logic_vector(4 downto 0) :="10011";
constant opANDCCI:std_logic_vector(4 downto 0):="10100";
constant opORCCI:std_logic_vector(4 downto 0) :="10101";
constant opANDI: std_logic_vector(4 downto 0) :="10110";
constant opORI:  std_logic_vector(4 downto 0) :="10111";
constant opXORI: std_logic_vector(4 downto 0) :="11000";
constant opCMPI: std_logic_vector(4 downto 0) :="11001";
constant opBITI: std_logic_vector(4 downto 0) :="11010";
constant opBR:   std_logic_vector(4 downto 0) :="11011";
constant opCALR: std_logic_vector(4 downto 0) :="11100";
constant opRTNI: std_logic_vector(4 downto 0) :="11101";
constant opSHFI: std_logic_vector(4 downto 0) :="11110";
constant opLUTI: std_logic_vector(4 downto 0) :="11111";

--  ir(17..11) condition code "skip always" used for additional instructions
constant opLUT1:  std_logic_vector(2 downto 0) :="000";
constant opLUT2:  std_logic_vector(2 downto 0) :="001";
constant opLUT4:  std_logic_vector(2 downto 0) :="010";
constant opLUT8:  std_logic_vector(2 downto 0) :="011";
constant opLUT16: std_logic_vector(2 downto 0) :="100";
constant opBRA:   std_logic_vector(2 downto 0) :="101";
constant opCALLA: std_logic_vector(2 downto 0) :="110";
constant opSHFT2: std_logic_vector(2 downto 0) :="110";

--  ir(8..0) sub op-codes
constant opHLT: std_logic_vector(8 downto 0) :="000000000";
constant opRTN: std_logic_vector(8 downto 0) :="000000001";

--  ir(16..13) condition codes
constant ccZ:   std_logic_vector(3 downto 0) :="0000";
constant ccNZ:  std_logic_vector(3 downto 0) :="0001";
constant ccC:   std_logic_vector(3 downto 0) :="0010";
constant ccNC:  std_logic_vector(3 downto 0) :="0011";
constant ccPL:  std_logic_vector(3 downto 0) :="0100";
constant ccMI:  std_logic_vector(3 downto 0) :="0101";
constant ccSKN: std_logic_vector(3 downto 0) :="0110";
constant ccSKA: std_logic_vector(3 downto 0) :="0111";
constant ccPO:  std_logic_vector(3 downto 0) :="1000";
constant ccPE:  std_logic_vector(3 downto 0) :="1001";
constant ccGT:  std_logic_vector(3 downto 0) :="1010";
constant ccLE:  std_logic_vector(3 downto 0) :="1011";
constant ccA1S: std_logic_vector(3 downto 0) :="1100";
constant ccNA1: std_logic_vector(3 downto 0) :="1101";
constant ccOD:  std_logic_vector(3 downto 0) :="1110";
constant ccEV:  std_logic_vector(3 downto 0) :="1111";

end definitions;
