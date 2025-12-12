-- hay4stk16_32_defs.vhd    32-bit instructions, 16-bit quad stack with frame & thread pointers
-- type declarations & constants
--  (c) James Brakefield, 2014

library IEEE;
use IEEE.std_logic_1164.all;

package definitions is
-- memory configurations
-- instruction memory
constant IADR_BITS: natural := 10;
constant IWORD_SZ:  natural := 32;
-- Data RAM
constant DADR_BITS: natural := 11;
constant DWORD_SZ:  natural := 16;
-- IO
constant IOWORD_SZ:  natural := 16;

--		Instruction processing phase
constant Phase1: std_logic:='0';
constant Phase2: std_logic:='1';

--		Control signals, control signal name suffixed by _input name
--			2nd operand SP
constant SPm_ctrl_SP0: std_logic_vector(1 downto 0) :="00";
constant SPm_ctrl_SP1: std_logic_vector(1 downto 0) :="01";
constant SPm_ctrl_SP2: std_logic_vector(1 downto 0) :="10";
constant SPm_ctrl_SP3: std_logic_vector(1 downto 0) :="11";
--			2nd operand pointer register
constant FTP_ctrl_FP: std_logic_vector(1 downto 0) :="00";
constant FTP_ctrl_TP: std_logic_vector(1 downto 0) :="01";
constant FTP_ctrl_PC: std_logic_vector(1 downto 0) :="10";
constant FTP_ctrl_z:  std_logic_vector(1 downto 0) :="11";
--			2nd operand register mux
constant EA_ctrl_SPm: std_logic :='0';
constant EA_ctrl_FTP: std_logic :='1';
--			2nd operand for EA ALU
constant EA_alu_ctrl_z: std_logic_vector(1 downto 0) :="00";		-- 2nd alu input is 0 (plus carry in)
constant EA_alu_ctrl_m1: std_logic_vector(1 downto 0) :="01";		-- 2nd ALU input is -1
constant EA_alu_ctrl_delta: std_logic_vector(1 downto 0) :="10";	-- 2nd ALU input is delta
constant EA_alu_ctrl_ndelta:  std_logic_vector(1 downto 0) :="11";	-- 2nd ALU input is NOT delta (plus carry in)
--			next PC arithmetic control
constant PCp1_ctrl_PCp0:  std_logic :='0';
constant PCp1_ctrl_PCpN:  std_logic :='1';
--			input mux for PC
constant PC_ctrl_EA: 	std_logic_vector(1 downto 0) :="00";
constant PC_ctrl_SPn:	std_logic_vector(1 downto 0) :="01";
constant PC_ctrl_PCp1:	std_logic_vector(1 downto 0) :="10";
constant PC_ctrl_MDO:	std_logic_vector(1 downto 0) :="11";
--			input mux for pointer register updates (FP, TP, SPn)
constant ptr_ctrl_EA: 	std_logic_vector(1 downto 0) :="00";
constant ptr_ctrl_EAW: 	std_logic_vector(1 downto 0) :="01";
constant ptr_ctrl_op2:	std_logic_vector(1 downto 0) :="10";
constant ptr_ctrl_SPnp1:std_logic_vector(1 downto 0) :="11";

--						SPn and FP/TP/SPn update controls
--			1st operand
constant SPn_ctrl_SP0: std_logic_vector(1 downto 0) :="00";
constant SPn_ctrl_SP1: std_logic_vector(1 downto 0) :="01";
constant SPn_ctrl_SP2: std_logic_vector(1 downto 0) :="10";
constant SPn_ctrl_SP3: std_logic_vector(1 downto 0) :="11";
--			input mux for MDI/MDO address
constant EAW_sel_SPn: std_logic :='0';
constant EAW_sel_EA:  std_logic :='1';
--			FP/TP update mux controls
constant fptp_ctrl_EA:	std_logic :='0';
constant fptp_ctrl_MDO:	std_logic :='1';
--			SPn update mux controls
constant SP0_ctrl_EA: 		std_logic :='0';
constant SP0_ctrl_SPpm1:	std_logic :='1';
constant SP1_ctrl_EA: 		std_logic :='0';
constant SP1_ctrl_SPpm1:	std_logic :='1';
constant SP2_ctrl_EA: 		std_logic :='0';
constant SP2_ctrl_SPpm1:	std_logic :='1';
constant SP3_ctrl_EA: 		std_logic :='0';
constant SP3_ctrl_SPpm1:	std_logic :='1';


--						ALU controls
--			ALU carry in control
constant cin_ctrl_0:   std_logic :='0';
constant cin_ctrl_1:   std_logic :='1';
--			ALU 2nd operand mux control
constant op2_ctrl_in2:	std_logic_vector(2 downto 0) :="000";
constant op2_ctrl_in3:	std_logic_vector(2 downto 0) :="001";
constant op2_ctrl_ccr0:	std_logic_vector(2 downto 0) :="010";
constant op2_ctrl_ccr1:	std_logic_vector(2 downto 0) :="011";
constant op2_ctrl_IR20:	std_logic_vector(2 downto 0) :="100";
constant op2_ctrl_IR21:	std_logic_vector(2 downto 0) :="101";
constant op2_ctrl_MDO:	std_logic_vector(2 downto 0) :="110";
constant op2_ctrl_EA:	std_logic_vector(2 downto 0) :="111";
--			Boolean control
constant bool_ctrl_z:		std_logic_vector(2 downto 0) :="000";
constant bool_ctrl_nMDO: 	std_logic_vector(2 downto 0) :="001";
constant bool_ctrl_1and2:	std_logic_vector(2 downto 0) :="010";
constant bool_ctrl_1andn2: std_logic_vector(2 downto 0) :="011";
constant bool_ctrl_n1and2:	std_logic_vector(2 downto 0) :="100";
constant bool_ctrl_1or2:	std_logic_vector(2 downto 0) :="101";
constant bool_ctrl_1xor2:	std_logic_vector(2 downto 0) :="110";
constant bool_ctrl_MDO:  	std_logic_vector(2 downto 0) :="111";
--			ALU control
constant ALU_ctrl_MDO:  	std_logic_vector(2 downto 0) :="000";
constant ALU_ctrl_nMDO: 	std_logic_vector(2 downto 0) :="001";
constant ALU_ctrl_op2:		std_logic_vector(2 downto 0) :="010";
constant ALU_ctrl_nop2:		std_logic_vector(2 downto 0) :="011";
constant ALU_ctrl_z:			std_logic_vector(2 downto 0) :="100";
constant ALU_ctrl_add:		std_logic_vector(2 downto 0) :="101";
constant ALU_ctrl_sub:		std_logic_vector(2 downto 0) :="110";
constant ALU_ctrl_rsub:		std_logic_vector(2 downto 0) :="111";
--			input mux for MDI
constant DID_ctrl_ALU: 	 std_logic_vector(2 downto 0) :="000";
constant DID_ctrl_SPn:  std_logic_vector(2 downto 0) :="001";
constant DID_ctrl_mull:  std_logic_vector(2 downto 0) :="010";
constant DID_ctrl_mulu:  std_logic_vector(2 downto 0) :="011";
constant DID_ctrl_FP: 	 std_logic_vector(2 downto 0) :="100";
constant DID_ctrl_TP: 	 std_logic_vector(2 downto 0) :="101";
constant DID_ctrl_PCp1: std_logic_vector(2 downto 0) :="110";
constant DID_ctrl_EA:  	 std_logic_vector(2 downto 0) :="111";

-- instruction assignments						  			R & XXXXX		P=0 (stack mode, v:push, ^: pop)						P=1 (reverse stack/accumulator mode)
constant opCALL:  	std_logic_vector(5 downto 0) :="000001";	--store PC+1 to vACCn										--store PC+1 to ACCn
constant opRTN:		std_logic_vector(5 downto 0) :="000001";	--load ACCn^ to PC											--load ACCn to PC
constant opSOBR:		std_logic_vector(5 downto 0) :="100001";	--decrement ACCn and branch not zero, R=1				--not defined
constant opLSPwEA:	std_logic_vector(5 downto 0) :="000100";	--load SPn with EA											--not possible
constant opLTPwEA:	std_logic_vector(5 downto 0) :="000100";	--not possible													--load TP with EA, P=1, n=2
constant opLPCwEA:	std_logic_vector(5 downto 0) :="000100";	--not possible													--load PC with EA, P=1, n=3
constant opLDEA:		std_logic_vector(5 downto 0) :="100100";	--load vACCn with EA											--load ACCn with EA
constant opLDFP:		std_logic_vector(5 downto 0) :="100101";	--load FP with M(EA), n=0									--not defined
constant opSTFP:		std_logic_vector(5 downto 0) :="100101";	--store FP to M(EA), n=0, R=1								--not defined
constant opLDtP:		std_logic_vector(5 downto 0) :="100101";	--load FP with M(EA), n=1									--not defined
constant opSTtP:		std_logic_vector(5 downto 0) :="100101";	--store FP to M(EA), n=1, R=1								--not defined
constant opJMP:		std_logic_vector(5 downto 0) :="100101";	--load PC with M(EA), n=2									--not defined
constant opSTPC:		std_logic_vector(5 downto 0) :="100101";	--store PC+1 to M(EA), n=2, R=1							--not defined
constant opLD:			std_logic_vector(5 downto 0) :="000110";	--load vACCn with M(EA)										--load ACCn with M(EA)
constant opLDI:		std_logic_vector(5 downto 0) :="000110";	--load vACCn with N, T=1, m=6-7							--load ACCn with N
constant opST:			std_logic_vector(5 downto 0) :="100011";	--store ACCn^ to M(EA), R=1								--store ACCn to M(EA), R=1
constant opLDSPn:		std_logic_vector(5 downto 0) :="000111";	--load SPn with M(EA)										--not defined
constant opSTSPn:		std_logic_vector(5 downto 0) :="100111";	--store SPn to M(EA), R=1									--not defined
constant opINC:		std_logic_vector(5 downto 0) :="101100";	--increment M(EA), n=0, R=1								--not defined
constant opCLR:		std_logic_vector(5 downto 0) :="101100";	--clear M(EA), n=1, R=1										--not defined
constant opDEC:		std_logic_vector(5 downto 0) :="101100";	--deccrement M(EA), n=2, R=1								--not defined
constant opSET:		std_logic_vector(5 downto 0) :="101100";	--set M(EA) to all ones, n=3, R=1						--not defined
constant opCMP:		std_logic_vector(5 downto 0) :="001101";	--compare ACCn^ with M(EA)									--compare ACCn with M(EA)
constant opCMPI:		std_logic_vector(5 downto 0) :="001101";	--compare ACCn^ with N, T=1, m=6-7						--compare ACCn with N, T=1, m=6-7
constant opBIT:		std_logic_vector(5 downto 0) :="001110";	--and ACCn^ with M(EA), set ZME CCR bits				--and ACCn with M(EA), set ZME CCR bits
constant opBITI:		std_logic_vector(5 downto 0) :="001110";	--and ACCn^ with N, set ZME CCR bits, T=1, m=6-7	--and ACCn with N, set ZME CCR bits, T=1, m=6-7
constant opAND:		std_logic_vector(5 downto 0) :="010100";	--ACCn AND M(EA) to ACCn									--ACCn AND M(EA) to vACCn
constant opANDI:		std_logic_vector(5 downto 0) :="010100";	--ACCn AND N to ACCn, T=1, m=6-7							--ACCn AND N to vACCn, T=1, m=6-7
constant opRAND:		std_logic_vector(5 downto 0) :="110100";	--ACCn^ AND M(EA) to M(EA), R=1							--ACCn AND M(EA) to M(EA), R=1
constant opANDN:		std_logic_vector(5 downto 0) :="010101";	--ACCn AND not M(EA) to ACCn								--ACCn AND not M(EA) to vACCn
constant opANDNI:		std_logic_vector(5 downto 0) :="010101";	--ACCn AND not N to ACCn, T=1, m=6-7					--ACCn AND not N to vACCn, T=1, m=6-7
constant opRANDN:		std_logic_vector(5 downto 0) :="110101";	--not ACCn^ AND M(EA) to M(EA), R=1						--not ACCn AND M(EA) to M(EA), R=1
constant opOR:			std_logic_vector(5 downto 0) :="010110";	--ACCn OR M(EA) to ACCn										--ACCn OR M(EA) to vACCn
constant opORI:		std_logic_vector(5 downto 0) :="010110";	--ACCn OR N to ACCn, T=1, m=6-7							--ACCn OR N to vACCn, T=1, m=6-7
constant opROR:		std_logic_vector(5 downto 0) :="110110";	--ACCn^ OR M(EA) to M(EA), R=1							--ACCn OR M(EA) to M(EA), R=1
constant opXOR:		std_logic_vector(5 downto 0) :="010111";	--ACCn XOR M(EA) to ACCn									--ACCn XOR M(EA) to vACCn
constant opXORI:		std_logic_vector(5 downto 0) :="010111";	--ACCn XOR N to ACCn, T=1, m=6-7							--ACCn XOR N to vACCn, T=1, m=6-7
constant opRXOR:		std_logic_vector(5 downto 0) :="110111";	--ACCn^ XOR M(EA) to M(EA), R=1							--ACCn XOR M(EA) to M(EA), R=1
constant opADD:		std_logic_vector(5 downto 0) :="011000";	--ACCn plus M(EA) to ACCn									--ACCn plus M(EA) to vACCn
constant opADDI:		std_logic_vector(5 downto 0) :="011000";	--ACCn plus N to ACCn, T=1, m=6-7						--ACCn plus N to vACCn, T=1, m=6-7
constant opRADD:		std_logic_vector(5 downto 0) :="111000";	--ACCn^ plus M(EA) to M(EA), R=1							--ACCn plus M(EA) to M(EA), R=1
constant opSUB:		std_logic_vector(5 downto 0) :="011001";	--ACCn minus M(EA) to ACCn									--ACCn minus M(EA) to vACCn
constant opSUBI:		std_logic_vector(5 downto 0) :="011001";	--ACCn minus N to ACCn, T=1, m=6-7						--ACCn minus N to vACCn, T=1, m=6-7
constant opRSUB:		std_logic_vector(5 downto 0) :="111001";	--M(EA) minus ACCn^ to M(EA), R=1						--M(EA) minus ACCn to M(EA), R=1
constant opADC:		std_logic_vector(5 downto 0) :="011010";	--ACCn plus M(EA) plus C to ACCn							--ACCn plus M(EA) plus C to vACCn
constant opADCI:		std_logic_vector(5 downto 0) :="011010";	--ACCn plus N plus C to ACCn, T=1, m=6-7				--ACCn plus N plus C to vACCn, T=1, m=6-7
constant opRADC:		std_logic_vector(5 downto 0) :="111010";	--ACCn^ plus M(EA) plus C to M(EA), R=1				--ACCn plus M(EA) plus C to M(EA), R=1
constant opSBB:		std_logic_vector(5 downto 0) :="011011";	--ACCn minus M(EA) plus C to ACCn						--ACCn minus M(EA) plus C to vACCn
constant opSBBI:		std_logic_vector(5 downto 0) :="011011";	--ACCn minus N plus C to ACCn, T=1, m=6-7				--ACCn minus N plus C to vACCn, T=1, m=6-7
constant opRSBB:		std_logic_vector(5 downto 0) :="111011";	--M(EA) minus ACCn^ plus C to M(EA), R=1				--M(EA) minus ACCn plus C to M(EA), R=1
constant opMUL:		std_logic_vector(5 downto 0) :="011101";	--ACCn times M(EA) to ACCn									--ACCn times M(EA) to vACCn
constant opMULI:		std_logic_vector(5 downto 0) :="011101";	--ACCn times N to ACCn, T=1, m=6-7						--ACCn times N to vACCn, T=1, m=6-7
constant opRMUL:		std_logic_vector(5 downto 0) :="111101";	--ACCn^ times M(EA) to M(EA), R=1						--ACCn times M(EA) to M(EA), R=1
constant opMULU:		std_logic_vector(5 downto 0) :="011110";	--(unsigned ACCn times M(EA))>>16 to ACCn				--(unsigned ACCn times M(EA))>>16 to vACCn
constant opMULUI:		std_logic_vector(5 downto 0) :="011110";	--(unsigned ACCn times N)>>16 to ACCn, T=1, m=6-7	--(unsigned ACCn times N)>>16 to vACCn, T=1, m=6-7
constant opRMULU:		std_logic_vector(5 downto 0) :="111110";	--(unsigned ACCn^ times M(EA))>>16 to M(EA), R=1	--(unsigned ACCn times M(EA))>>16 to M(EA), R=1
constant opMULUS:		std_logic_vector(5 downto 0) :="011111";	--(signed ACCn times M(EA))>>16 to ACCn				--(signed ACCn times M(EA))>>16 to vACCn
constant opMULUSI:	std_logic_vector(5 downto 0) :="011111";	--(signed ACCn times N)>>16 to ACCn, T=1, m=6-7		--(signed ACCn times N)>>16 to vACCn, T=1, m=6-7
constant opRMULUS:	std_logic_vector(5 downto 0) :="111111";	--(signed ACCn^ times M(EA))>>16 to M(EA), R=1		--(signed ACCn times M(EA))>>16 to M(EA), R=1

--  conditional branches								m0 & XXXXX
-- overflow if magnitude of result exceeds bit field to hold it, carry inverted after a subtract, carry in on subtract is a borrow
--		6809 Assembly Language Programming 1981, Lance Leventhal, also x86 & VAX-11, some variation BRGT/BRGL
--		overflow set if both operands are >=0 and result is <0 or if both operands are <0 and result is >=0
constant opNOP:	std_logic_vector(5 downto 0) :="010111";	-- branch never (NOP), R=1, T=1, m=6
constant opBR:		std_logic_vector(5 downto 0) :="110111";	-- branch always, R=1, T=1, m=7
constant opBREV:	std_logic_vector(5 downto 0) :="011000";	-- branch even, R=1, T=1, m=6
constant opBRODD:	std_logic_vector(5 downto 0) :="111000";	-- branch odd, R=1, T=1, m=7
constant opBRNZ:	std_logic_vector(5 downto 0) :="011001";	-- branch non-zero, also BRNE, R=1, T=1, m=6
constant opBRZ:	std_logic_vector(5 downto 0) :="111001";	-- branch zero, also BREQ, R=1, T=1, m=7
constant opBRCC:	std_logic_vector(5 downto 0) :="011010";	-- branch carry/borrow clear, also unsigned BRHS, R=1, T=1, m=6
constant opBRCS:	std_logic_vector(5 downto 0) :="111010";	-- branch carry/borrow set, also unsigned BRLO, R=1, T=1, m=7
constant opBROVC:	std_logic_vector(5 downto 0) :="011011";	-- branch no overflow, R=1, T=1, m=6
constant opBROVS:	std_logic_vector(5 downto 0) :="111011";	-- branch overflow set, R=1, T=1, m=7
constant opBRLT:	std_logic_vector(5 downto 0) :="011100";	-- branch less than (N xor V = 1), R=1, T=1, m=7
constant opBRGE:	std_logic_vector(5 downto 0) :="111100";	-- branch greater-equal (N xor V = 0), R=1, T=1, m=6
constant opBRP:	std_logic_vector(5 downto 0) :="011101";	-- branch plus, R=1, T=1, m=6
constant opBRM:	std_logic_vector(5 downto 0) :="111101";	-- branch minus, R=1, T=1, m=7
constant opBRLE:	std_logic_vector(5 downto 0) :="011110";	-- branch less than or equal (Z or (N xor V) = 1), R=1, T=1, m=7
constant opBRGT:	std_logic_vector(5 downto 0) :="111110";	-- branch greater than (Z or (N xor V) = 0), R=1, T=1, m=6
constant opBRLS:	std_logic_vector(5 downto 0) :="011111";	-- branch low-same unsigned(C or Z = 1), R=1, T=1, m=7
constant opBRHI:	std_logic_vector(5 downto 0) :="111111";	-- branch high unsigned(C or Z = 0), R=1, T=1, m=6

end definitions;

