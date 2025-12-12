-- lem18_18m_defs.vhd    minimized LEM16_18
-- type declarations & constants
-- instruction formats are:
--   bit field         4: data size, 6: op-code, 8: data address
--   jump/call         4: condition code, 4: op-code, 10: program address
--   lut               8: op-code, 10: program address
--   rtn/pred/misc     4: condition code, 6: op-code, 8: immediate

library IEEE;
use IEEE.std_logic_1164.all;

package definitions is

-- memory configurations
-- instruction & LUT table memory
constant IADR_BITS: natural := 10;
constant IWORD_SZ:  natural := 18;
-- data RAM
constant DADR_BITS: natural := 4;
constant DWORD_SZ:  natural := 16;
-- return stack  & data stack
constant RDADR_BITS: natural := 4;
constant RDWORD_SZ:  natural := 16;

-- machine instructions memonics sorted by code & sub-code
--  operations with size field
constant opALU:  std_logic_vector(5 downto 0) :="00----";
constant opADD:  std_logic_vector(5 downto 0) :="000000";
constant opADC:  std_logic_vector(5 downto 0) :="000001";
constant opSUB:  std_logic_vector(5 downto 0) :="000010";
constant opSBC:  std_logic_vector(5 downto 0) :="000011";
constant opLD:   std_logic_vector(5 downto 0) :="000100";
constant opAND:  std_logic_vector(5 downto 0) :="000101";
constant opOR:   std_logic_vector(5 downto 0) :="000110";
constant opXOR:  std_logic_vector(5 downto 0) :="000111";
constant opST:   std_logic_vector(5 downto 0) :="001000";
constant opLDC:  std_logic_vector(5 downto 0) :="001001";
constant opBIT:  std_logic_vector(5 downto 0) :="001010";
constant opCMP:  std_logic_vector(5 downto 0) :="001011";
constant opINC:  std_logic_vector(5 downto 0) :="001100";
constant opDEC:  std_logic_vector(5 downto 0) :="001101";
constant opCLR:  std_logic_vector(5 downto 0) :="001110";
constant opSET:  std_logic_vector(5 downto 0) :="001111";

--  operations with conditional execution & 8-bit immediate
constant opIMM:   std_logic_vector(5 downto 0) :="01----";
constant opADDI:  std_logic_vector(5 downto 0) :="010000";
constant opADDIU: std_logic_vector(5 downto 0) :="011000";
constant opSUBI:  std_logic_vector(5 downto 0) :="010001";
constant opSUBIU: std_logic_vector(5 downto 0) :="011001";
constant opLDI:   std_logic_vector(5 downto 0) :="010010";
constant opLDIU:  std_logic_vector(5 downto 0) :="011010";
constant opANDI:  std_logic_vector(5 downto 0) :="010011";
constant opANDIU: std_logic_vector(5 downto 0) :="011011";
constant opORI:   std_logic_vector(5 downto 0) :="010100";
constant opORIU:  std_logic_vector(5 downto 0) :="011100";
constant opXORI:  std_logic_vector(5 downto 0) :="010101";
constant opXORIU: std_logic_vector(5 downto 0) :="011101";
constant opCMPI:  std_logic_vector(5 downto 0) :="010110";
constant opCMPIU: std_logic_vector(5 downto 0) :="011110";
constant opBITI:  std_logic_vector(5 downto 0) :="010111";
constant opBITIU: std_logic_vector(5 downto 0) :="011111";

--  operations with conditional execution & 10-bit address
constant opJMPcc:  std_logic_vector(5 downto 0) :="1000--";
constant opCALLcc: std_logic_vector(5 downto 0) :="1001--";
constant opJMP00:  std_logic_vector(5 downto 0) :="100000";
constant opJMP01:  std_logic_vector(5 downto 0) :="100001";
constant opJMP10:  std_logic_vector(5 downto 0) :="100010";
constant opJMP11:  std_logic_vector(5 downto 0) :="100011";
constant opCALL00: std_logic_vector(5 downto 0) :="100100";
constant opCALL01: std_logic_vector(5 downto 0) :="100101";
constant opCALL10: std_logic_vector(5 downto 0) :="100110";
constant opCALL11: std_logic_vector(5 downto 0) :="100111";

--  LUT instructions, op-code suffix is size of result, 10-bit address
constant opLUT:    std_logic_vector(5 downto 0) :="1010--";
constant opLUT00:  std_logic_vector(5 downto 0) :="101000";
constant opLUT01:  std_logic_vector(5 downto 0) :="101001";
constant opLUT10:  std_logic_vector(5 downto 0) :="101010";
constant opLUT11:  std_logic_vector(5 downto 0) :="101011";
constant opLUT1:   std_logic_vector(3 downto 0) :="0000";
constant opLUT2:   std_logic_vector(3 downto 0) :="0001";
constant opLUT4:   std_logic_vector(3 downto 0) :="0010";
constant opLUT8:   std_logic_vector(3 downto 0) :="0011";
constant opLUT16:  std_logic_vector(3 downto 0) :="0100";
-- three unused    std_logic_vector(3 downto 0) :="01xx";
constant opLUT1B:  std_logic_vector(3 downto 0) :="1000";
constant opLUT2B:  std_logic_vector(3 downto 0) :="1001";
constant opLUT4B:  std_logic_vector(3 downto 0) :="1010";
constant opLUT8B:  std_logic_vector(3 downto 0) :="1011";
-- four unused     std_logic_vector(3 downto 0) :="11xx";
--  LUT immediate & predicate instructions
--  LUTI does not use ir(17..14), could be conditional
constant opLUTI:   std_logic_vector(5 downto 0) :="1011--";
constant opLUT1I:  std_logic_vector(5 downto 0) :="101100";
constant opLUT2I:  std_logic_vector(5 downto 0) :="101101";
constant opLUT4I:  std_logic_vector(5 downto 0) :="101110";
constant opPRED:   std_logic_vector(5 downto 0) :="101111";

--  ir(5..0) MISC op-codes with conditional execution & 8-bit immediate
constant opMISC:    std_logic_vector(5 downto 0) :="11----";
constant opRTNIcc:  std_logic_vector(5 downto 0) :="110000";
constant opRTNcc:   std_logic_vector(5 downto 0) :="110001";
constant opADCI:    std_logic_vector(5 downto 0) :="110010";
constant opSBCI:    std_logic_vector(5 downto 0) :="110011";
constant opANISR:   std_logic_vector(5 downto 0) :="110100";
constant opORISR:   std_logic_vector(5 downto 0) :="110101";
constant opPUSHA:   std_logic_vector(5 downto 0) :="110110";
constant opPUSHPC:  std_logic_vector(5 downto 0) :="110111";
constant opPOPA:    std_logic_vector(5 downto 0) :="111000";
constant opDISCRD:  std_logic_vector(5 downto 0) :="111001";
constant opHALT:    std_logic_vector(5 downto 0) :="111010";
constant opWAIT:    std_logic_vector(5 downto 0) :="111011";
constant opNOP:     std_logic_vector(5 downto 0) :="111100";
-- three unused     std_logic_vector(5 downto 0) :="1111xx";

--  ir(17..14) condition code assignments
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

