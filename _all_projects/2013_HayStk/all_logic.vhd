----------------------------------------------------------------------------------
-- Company:			Brakefield Research
-- Engineer:		James Brakefield
-- 
-- Create Date:		04/24/2014 
-- Design Name:		all_logic
-- Module Name:		all_logic - Behavioural 
-- Project Name:		hay4stk16_32
-- Target Devices: 
-- Tool versions: 
-- Description:		All combinatorial logic for hay4stk16_32, next level up contains clock & RAMs
--		HYbrid architecture Accumulator and Addressable STacK processor
--		Four accumulators and associated stacks, 16-bit data, 32-bit instructions
--		Accumulators reside on the stacks and are at the stack pointer location
--		In general stacks may be ascending or descending (D=0 or D=1), here D="1111"
--		Stack 0 is used to hold "default stack" return addresses
--		16-bit data only, 32-bit instructions only
--		Address map (in 16-bit words):
--			0..1019:	Dual Port RAM, CCR & IO outs written to 1020..1023
--			1020..1023:	locations 1020-21 are 32 inputs and 32 outputs, locations 1022-23 are 32-bit CCR
--
-- Dependencies: 
--
-- Revision:
-- Last Edit:		04/24/2014 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_signed.all;
use work.definitions.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity all_logic is
    Port ( pc :     in STD_LOGIC_VECTOR (11 downto 0);		-- program counter, low bit always zero
           pcx :   out STD_LOGIC_VECTOR (11 downto 0);		-- update value for PC
			  state :  in STD_LOGIC;									-- current instruction processing state: Phase 0, 1 or 2
			  statex :out STD_LOGIC;									-- next instruction processing state: Phase 0, 1 or 2
           tp :     in STD_LOGIC_VECTOR (11 downto 0);		-- Thread Pointer, low bit always zero
           fp :     in STD_LOGIC_VECTOR (11 downto 0);		-- Frame Pointer, low bit always zero
           tpfpx :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for FP or TP
           sp0 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP0: first stack pointer, word addressing
           sp1 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP1: second stack pointer, word addressing
           sp2 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP2: third stack pointer, word addressing
           sp3 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP3: fourth stack pointer, word addressing
           spnx :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for SPn
           ccr :    in STD_LOGIC_VECTOR (31 downto 0);		-- condition code register: C3-0, V3-0, Z3-0, MSB3-0, P3-0, LSB3-0, DD3-0, DSZ1-0, INTE, INTT 
           ccrx :  out STD_LOGIC_VECTOR (31 downto 0);		-- update values for CCR
           IRadr : out STD_LOGIC_VECTOR  (9 downto 0);		-- DP RAM port A address, instruction & data reads
           MDadr : out STD_LOGIC_VECTOR (10 downto 0);		-- DP RAM port B address, data reads and data writes
           ir :     in STD_LOGIC_VECTOR (31 downto 0);		-- instruction "register", AKA DP RAM port A output value (dpdoa), 32-bits wide
           ir2 :    in STD_LOGIC_VECTOR (31 downto 0);		-- registered IR for Phase2 & Phase3 processing
           MDI :   out STD_LOGIC_VECTOR (15 downto 0);		-- DP RAM port B data input
           MDO :    in STD_LOGIC_VECTOR (15 downto 0);		-- DP RAM port B output value, 16-bits wide
           regxe : out STD_LOGIC_VECTOR  (8 downto 0);		-- combined update enables and write enables
           ccrxe : out STD_LOGIC_VECTOR (11 downto 0);		-- CCR update bit enables and nibble enables
           ioin2_3: in STD_LOGIC_VECTOR (31 downto 0);		-- Input ports 2 & 3 (locations -3 & -4), CCR is input ports 0 & 1 (locations -1 & -2)
          ioout2_3:out STD_LOGIC_VECTOR (31 downto 0));		-- Output port 2 & 3 (locations -3 & -4), CCR is output ports 0 & 1 (locations -1 & -2)
end all_logic;

architecture Behavioral of all_logic is
--		CCR sub-fields
signal C: std_logic_vector(3 downto 0);		-- carry status bits, one per accumulator
signal V: std_logic_vector(3 downto 0);		-- overflow status bits, one per accumulator
signal Z: std_logic_vector(3 downto 0);		-- zero status bits, one per accumulator
signal MSB: std_logic_vector(3 downto 0);		-- sign (MBS) status bits, one per accumulator
signal PT: std_logic_vector(3 downto 0);		-- parity status bits, one per accumulator
signal LSB: std_logic_vector(3 downto 0);		-- LSB status bits, one per accumulator
signal D: std_logic_vector(3 downto 0);		-- stack direction bits, one per accumulator, used for push/pop direction
signal DSZ: std_logic_vector(1 downto 0);		-- default data size, here is "01": 0: 8-bit, 1: 16-bit, 2: 32-bit, 3:64-bit
signal INTE: std_logic;								-- interrupts enabled
signal INTT: std_logic;								-- interrupt taken
--		IR & IR2 sub-fields
signal OP,OP2: std_logic_vector(4 downto 0);	-- op-code
signal L,L2:   std_logic_vector(1 downto 0);	-- stack pointer selector for 1st operand
signal M,M2 :  std_logic_vector(2 downto 0);	-- index register/2nd operand selector: effective address is: (SP0, SP1, SP2, SP3, FP, TP, PC or 0)+/-N
signal S,S2:   std_logic;							-- NN's sign, used to complement NN for negative values
signal NN,NN2: std_logic_vector(14 downto 0);-- unsigned immediate or offset value, negative values via one's complement of NN
signal R,R2:   std_logic;							-- replace operation, result replaces 2nd operand, if M is PC+/-N or N, instruction uses N as an immediate
signal PPC,PPC2: std_logic;						-- restore previous PC
signal P,P2:   std_logic;							-- pop/push stack of 1st operand
signal T,T2:   std_logic;							-- update index register of 2nd operand by displacement (N)
signal SZ,SZ2: std_logic_vector(1 downto 0);	-- data size: 0: 8-bit, 1: 16-bit, 2: 32-bit, 3:64-bit; here only 16-bit used
--		CCR update enables, forwarded to ccrxe
signal Cxe: std_logic;			-- carry nibble update enable
signal Vxe: std_logic;			-- overflow update enable
signal Zxe: std_logic;			-- zero status update enable
signal MSBxe: std_logic;		-- sign bit status update enable
signal PTxe: std_logic;			-- parity bit status update enable
signal LSBxe: std_logic;		-- LSB update enable
signal Dxe: std_logic;			-- direction bit update enable
signal CCR7xe: std_logic;		-- SZ and INT nibble update enable
signal DSZxe: std_logic;		-- default size field update enable
signal INTExe: std_logic;		-- interrupt enabled update enable
signal INTTxe: std_logic;		-- interrupt taken update enable
signal ccrxbe0: std_logic;		-- bit 0 within CCR nible update enable
signal ccrxbe1: std_logic;		-- bit 1 within CCR nibble update enable
signal ccrxbe2: std_logic;		-- bit 2 within CCR nibble update enable
signal ccrxbe3: std_logic;		-- bit 3 within CCR nibble update enable
--		Register and RAM update enables, forwarded to regxe
signal pcxe: std_logic;			-- PC update enable
signal tpxe: std_logic;			-- thread pointer update enable
signal fpxe: std_logic;			-- frame pointer update enable
signal sp0xe: std_logic;		-- stack pointer 0 update enable
signal sp1xe: std_logic;		-- stack pointer 1 update enable
signal sp2xe: std_logic;		-- stack pointer 2 update enable
signal sp3xe: std_logic;		-- stack pointer 3 update enable
signal memwe: std_logic;		-- dual port RAM write enable
signal io2xe: std_logic;		-- IO port 2 write enable
--		temporaries
signal CCR_tmp: std_logic_vector(6 downto 0);			-- CCR bits for selected accumulator
signal C_tmp: std_logic;										-- carry from CCR
signal BR_tmp: std_logic;										-- branch taken
signal delta: std_logic_vector(15 downto 0);				-- S combined with NN
signal SPn_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- 1st operand stack pointer mux out
signal SPm_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- 2nd operand stack pointer mux out
signal FTP_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- pointer register mux out
signal EAreg_tmp: STD_LOGIC_VECTOR (15 downto 0);		-- EA register mux out
signal ea_N_tmp: STD_LOGIC_VECTOR (15 downto 0);		-- EA (effective address) 2nd operand input
signal EA_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- EA (effective address) ALU out
signal EAW_alu_tmp: STD_LOGIC_VECTOR (15 downto 0);	-- EAW (effective write address) ALU in
signal EAW_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- EAW (effective write address) ALU out
signal AFTP_tmp: std_logic_vector(15 downto 0);			-- FP, TP, PC+1, ALU mux output to DID mux
signal DID_tmp: std_logic_vector(15 downto 0);			-- data for writing to QPM and block RAM
signal PCp1_tmp: STD_LOGIC_VECTOR (15 downto 0);		-- "PC + 1", output of PC ALU
signal PC_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- next PC
signal op2_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- 2nd operand MUX output
signal bool_tmp: STD_LOGIC_VECTOR (15 downto 0);		-- 1st operand: 0, a or not a select
signal MUX_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- 2nd operand:0, opnd2_tmp, not opnd2_tmp
signal cin_tmp: STD_LOGIC;										-- carry to ALU
signal ALU_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- ALU output
signal mult_tmp: STD_LOGIC_VECTOR (33 downto 0);		-- multiplier output
signal regxe_tmp: STD_LOGIC_VECTOR (8 downto 0);		-- combined update enables and write enables
signal ccrxe_tmp: STD_LOGIC_VECTOR (11 downto 0);		-- CCR update bit enables and nibble enables
signal SPnp1_tmp:  STD_LOGIC_VECTOR (15 downto 0);		-- 
signal ptr_tmp: STD_LOGIC_VECTOR (15 downto 0);			-- mux output for loading pointer registers
signal nn_tmp: STD_LOGIC_VECTOR (11 downto 0);			-- input to PC adder
signal PC_cbit: STD_LOGIC;										-- PC adder carry input

--			Misc control signals
signal BR_ctrl,BR_ctrl0: std_logic;							-- BBcc relative branch to be taken
signal WE_ctrl: std_logic;										-- Memory write enable, on data port
signal IOwe: std_logic;											-- IO write enable, qualified by EAW_tmp
--			EA controls
signal SPm_ctrl: std_logic_vector(1 downto 0);			-- stack pointer selector for 2nd operand
signal FTP_ctrl: std_logic_vector(1 downto 0);			-- register selector for 2nd operand (FP,TP,PC or 0)
signal EA_ctrl: std_logic;										-- EA pointer selector for 2nd operand (SPm_tmp or FTP_tmp)
signal ea_alu_ctrl: std_logic_vector(1 downto 0);		-- EA adder 2nd input MUX
signal ea_alu_cin: std_logic;									-- EA adder carry in
--			EAW controls
signal EAW_m1, EAW_cin: STD_LOGIC;							--  carry in and -1 operand for SPn updates
signal SPn_ctrl: std_logic_vector(1 downto 0);			-- stack pointer selector for 1st operand
signal EAW_sel: std_logic;										-- EAW pointer selector for 2nd operand address (EA_tmp or SPn_tmp)
--			PC controls
signal PC_ctrl: std_logic_vector(1 downto 0);			-- select EA, op2, pcp1_ctrl_temp or MDO
signal pcp1_ctrl: std_logic_vector(2 downto 0);
--			ALU controls
signal cin_ctrl: STD_LOGIC_VECTOR (1 downto 0);			-- carry select for ALU
signal op2_ctrl: std_logic_vector(2 downto 0);			-- main ALU 1st operand source MUX control
signal bool_ctrl: STD_LOGIC_VECTOR (2 downto 0);		-- 0, a, not a, a|b, a&b or a^b select
signal ALU_ctrl: STD_LOGIC_VECTOR (2 downto 0);			-- b, ~b, a, ~a, 0, a+b, a-b, b-a
signal multsigns: STD_LOGIC;									-- multiply operand sign enable, both operands
signal AFTP_ctrl: STD_LOGIC_VECTOR (1 downto 0);		-- select ALU, PCp1, FP or TP
signal DID_ctrl: STD_LOGIC_VECTOR (1 downto 0);			-- select AFTP, mul, mulu, mul OR mul
--			FP, TP & SPn update controls
signal cin, m1: STD_LOGIC;										-- carry in and -1 operand for SPn updates
signal fptp_ctrl: std_logic;			-- control for TP & FP update mux
signal sp0_ctrl: std_logic;			-- control for SPn update mux
signal sp1_ctrl: std_logic;			-- control for SPn update mux
signal sp2_ctrl: std_logic;			-- control for SPn update mux
signal sp3_ctrl: std_logic;			-- control for SPn update mux

begin
--	CCR subfields
C <= CCR(3 downto 0);		V <= CCR(7 downto 4);		
Z <= CCR(11 downto 8);		MSB <= CCR(15 downto 12);
PT <= CCR(19 downto 16);	LSB <= CCR(23 downto 20);	
D <= CCR(27 downto 24);		DSZ <= CCR(29 downto 28);	INTE <= CCR(30);				INTT <= CCR(31);
--	IR subfields
OP <= IR(31 downto 27);		L <= IR(26 downto 25);		M <= IR(24 downto 22);		R <= IR(21);
PPC <= IR(20);					P <= IR(19);					T <= IR(18);					SZ <= IR(17 downto 16);
S <= IR(15);					NN <= IR(14 downto 0);
--	IR2 subfields
OP2 <= IR2(31 downto 27);	L2 <= IR2(26 downto 25);	M2 <= IR2(24 downto 22);	R2 <= IR2(21);
PPC2 <= IR2(20);				P2 <= IR2(19);					T2 <= IR2(18);					SZ2 <= IR2(17 downto 16);
S2 <= IR2(15);					NN2 <= IR2(14 downto 0);
--		CCR update enable subfields
CCRxe <= ccrxbe3 & ccrxbe2 & ccrxbe1 & ccrxbe0 & 
		CCR7xe & Dxe & LSBxe & PTxe & MSBxe & Zxe & Vxe & Cxe;
--		Register and RAM update enable subfields
regxe <= io2xe & memwe & pcxe & tpxe & fpxe & sp3xe & sp2xe & sp1xe & sp0xe;

--					CCR bits select for BCC op-code
process(L,D,LSB,PT,MSB,Z,V,C)
begin
case L is
	when SPn_ctrl_SP0 => CCR_tmp <= D(0)&LSB(0)&PT(0)&MSB(0)&Z(0)&V(0)&C(0);
	when SPn_ctrl_SP1 => CCR_tmp <= D(1)&LSB(1)&PT(1)&MSB(1)&Z(1)&V(1)&C(1);
	when SPn_ctrl_SP2 => CCR_tmp <= D(2)&LSB(2)&PT(2)&MSB(2)&Z(2)&V(2)&C(2);
	when SPn_ctrl_SP3 => CCR_tmp <= D(3)&LSB(3)&PT(3)&MSB(3)&Z(3)&V(3)&C(3);
	when others			=> CCR_tmp <= D(3)&LSB(3)&PT(3)&MSB(3)&Z(3)&V(3)&C(3);
end case;
end process;

--					CCRxbe0..3 generate
process(L)			-- one-hot ccrxbe0..3 outputs
begin
ccrxbe3<='0'; ccrxbe2<='0'; ccrxbe1<='0'; ccrxbe0<='0';
case L is
	when SPn_ctrl_SP0 => ccrxbe0 <= '1';
	when SPn_ctrl_SP1 => ccrxbe1 <= '1';
	when SPn_ctrl_SP2 => ccrxbe2 <= '1';
	when SPn_ctrl_SP3 => ccrxbe3 <= '1';
	when others			=> ccrxbe3 <= '1';
end case;
end process;

--					BR_ctrl generate (conditional branch taken)
process(OP,CCR_tmp)
begin
BR_ctrl <= '0';
case OP is					--  determine if branch to be taken for M=7
	when opBRODD(4 downto 0)	=> BR_ctrl0 <= CCR_tmp(5);								-- branch LSB = 1
	when opBRZ(4 downto 0)		=> BR_ctrl0 <= CCR_tmp(2);								-- branch zero
	when opBRCS(4 downto 0)		=> BR_ctrl0 <= CCR_tmp(0);								-- branch carry set
	when opBROVS(4 downto 0)	=> BR_ctrl0 <= CCR_tmp(1);								-- branch on overflow
	when opBRGE(4 downto 0)		=> BR_ctrl0 <= CCR_tmp(3) xor CCR_tmp(1);			-- branch signed GE (N xor V)
	when opBRM(4 downto 0) 		=> BR_ctrl0 <= CCR_tmp(3);								-- branch minu (MSB = 1)
	when opBRGT(4 downto 0)		=> BR_ctrl0 <= not((CCR_tmp(3) xor CCR_tmp(1)) or CCR_tmp(2));	-- branch signed GT
	when opBRHI(4 downto 0)		=> BR_ctrl0 <= not(CCR_tmp(0) or CCR_tmp(2));	-- branch unsigned GT
	when others 					=> BR_ctrl0 <= '1';										-- branch never (NOP)
end case;
end process;
					
process(BR_ctrl,M)		-- switch branch direction if M=6
begin
case M(0) is
	when '0'		=>	BR_ctrl <= not BR_ctrl0;
	when others => BR_ctrl <= BR_ctrl0;
end case;
end process;

--					Main Process: control signals generate
process(OP,OP2,L,M,R,PPC,P,T,SZ,S,NN,BR_ctrl,EA_tmp,WE_ctrl,EAW_tmp,state,R2,L2)
begin
--		Default values
statex <= Phase1;
--			CCR update enables
Cxe <= '0';				Vxe <= '0';			Zxe <= '0';			MSBxe <= '0';
PTxe <= '0';			LSBxe <= '0';		Dxe <= '0';			CCR7xe <= '0';
--			generic & specific write enables
WE_ctrl <= '0';		IOwe <= '0';		memwe <= '0';
--			register update enables
PCxe <= '1';			FPxe <= '0';		TPxe <= '0';		IO2xe <= '0';
SP0xe <= '0';			SP1xe <= '0';		SP2xe <= '0';		SP3xe <= '0';
--			carry in and -1 signals
EA_alu_cin <= '0';							-- for EA adder
m1 <= '0';				Cin <= '0';			-- +/-1 mechanism for SPn adders
multsigns <= '0';								-- set to do signed multiply

--			EA, PC & ALU controls: r, P & T bits always 0 for now 
--				Handle immediates			
if (T='1' and M = (EA_ctrl_FTP & FTP_ctrl_PC))		-- test for immediate
	then FTP_ctrl <= FTP_ctrl_z; 							-- immediate adjustment
	else FTP_ctrl <= M(1 downto 0); end if;
--				EA & EAW controls
EA_ctrl <= EA_ctrl_SPm;			
EA_alu_ctrl <= EA_alu_ctrl_z;		
--				PC and write data controls
PC_ctrl <= PC_ctrl_EA;		AFTP_ctrl <= AFTP_ctrl_SPn;		DID_ctrl <= DID_ctrl_ALU;
--			Data ALU controls
Bool_ctrl <= bool_ctrl_MDO;	Cin_ctrl <= cin_ctrl_0;
--				Operand 2 selection, EA_tmp selected in op-code cases
if (EA_tmp >= X"FFC") 		then op2_ctrl <= op2_ctrl_in2(2) & EAW_tmp(1 downto 0);		-- IO section of memory
	else								  op2_ctrl <= op2_ctrl_MDO(2 downto 1) & EAW_tmp(0);		-- RAM section of memory
	end if;
--				memory write enables
if (EAW_tmp >= X"FFC") 		then	IOwe <= WE_ctrl;				-- IO section of memory
	else									memwe <= WE_ctrl;				-- DP RAM section of memory
	end if;

--						Per signal or per control generation

--				Next state logic
if state = Phase2 then statex <= Phase1;	-- no Phase3 for now, default is Phase1
elsif M(2 downto 1) = "11" and T = '1' then 
	if R = '1' then statex <= Phase1;	-- conditional branches, for now, undefined branches do not use Phase2
	else 
		case R & OP is						-- immediates, R=0
		when opLDI => statex <= Phase1;
		when others => statex <= Phase2;
		end case;
	end if;
else 
	case R & OP is			-- Phase1 & not immediate or conditional branch
	when opCALL | opLSPwEA | opLDEA | opSTFP | opSTSPn => statex <= Phase1;
	when opCLR => if L(0) = '1' then statex <= Phase1; end if;		-- opSET as well
	when others => statex <= Phase2;
	end case;
end if;

--				MEMwe signal generation, default is '0'
case state is			
when Phase1 =>
	case R & OP is	
	when opCALL | opLDEA | opSTFP | opSTSPn => MEMwe <= '1';		-- opSTTP and opSTPC as well
	when opCLR => if L(0) = '1' then MEMwe <= '1'; end if;		-- opSET as well
	when opLDI => if M(2 downto 1) = "11" then MEMwe <= '1'; end if;
	when others => null;
	end case;
when Phase2 =>
	MEMwe <= '1';		-- default for Phase2, only matters if there is a Phase2
	case R2 & OP2 is
	when	opRTN | opLDEA | opLDFP | opLDSPn | opSTSPn | opCMP | opBIT => MEMwe <= '0';
	when	opINC => if L(0) = '0' then MEMwe <= '1'; end if;		-- opDEC as well
	when others => null;
	end case;
when others => null;
end case;


case state is			-- PC_ctrl generation
when Phase1 =>
	case R & OP is	
	when opBRCC | opBRCS => PC_ctrl <= PC_ctrl_PCp1;
	when others => null;
	end case;
when Phase2 =>
	case R2 & OP2 is
	when opCALL => PC_ctrl <= PC_ctrl_EA;
	when opLDFP => 
		case L2 is 
			when opfldn_FP | opfldn_TP => PC_ctrl <= PC_ctrl_EA;
			when opfldn_PC => PC_ctrl <= PC_ctrl_MDO;
			when others => null; 
			end case;
	when others => PC_ctrl <= PC_ctrl_PCp1;
	end case;
when others => null;
end case;

case state is			-- FPxe & TPxe signal generation
when Phase2 =>
	case R2 & OP2 is
	when opLDFP => if L2 = opfldn_FP then FPxe <= '1'; end if;
						if L2 = opfldn_TP then TPxe <= '1'; end if;	-- for opLDTP also
	when others => null;
	end case;
when others => null;
end case;

end process;

--					Data path MUXes and ALUs
--					Also carry signal MUXes

--						EA generate
SPm_ctrl <= M(1 downto 0);
--			SPm mux
process(sp0,sp1,sp2,sp3,SPm_ctrl)			-- 4:1 muxing of SP[L], generates QPM port B address
begin
case SPm_ctrl is
	when SPm_ctrl_SP0 => SPm_tmp <= "0000" & sp0;
	when SPm_ctrl_SP1 => SPm_tmp <= "0000" & sp1;
	when SPm_ctrl_SP2 => SPm_tmp <= "0000" & sp2;
	when SPm_ctrl_SP3 => SPm_tmp <= "0000" & sp3;
	when others			=> SPm_tmp <= "0000" & sp3;
end case;
end process;
--			FP/TP/PC/0 mux
process(PCp1_tmp,fp,tp,FTP_ctrl)					-- EA generation: 4:1 muxing of FP, TP, PC & 0
begin
case FTP_ctrl is
	when FTP_ctrl_FP => FTP_tmp <= "0000" & fp;
	when FTP_ctrl_TP => FTP_tmp <= "0000" & tp;
	when FTP_ctrl_PC => FTP_tmp <= PCp1_tmp;
	when FTP_ctrl_z  => FTP_tmp <= (others => '0');
	when others		  => FTP_tmp <= (others => '0');
end case;
end process;
--			SPm/FTP mux
process(SPm_tmp,FTP_tmp,EA_ctrl)			-- EA generation: 2:1 muxing of SP[M[1:0]] and (FP, TP, PC, 0)[M[1:0]]
begin
case EA_ctrl is
	when EA_ctrl_SPm => EAreg_tmp <= SPm_tmp;
	when EA_ctrl_FTP => EAreg_tmp <= FTP_tmp;
	when others => EAreg_tmp <= FTP_tmp;
end case;
end process;
--			N generate
delta <= S & ((S&S&S&S&S&S&S&S&S&S&S&S&S&S&S) XOR NN);			-- generate signed immediate
--			EA offset select mux
process(EAreg_tmp,delta,ea_alu_ctrl)		-- EA generation: 3:1 muxing of N, not N and either 0 or -1
begin
case ea_alu_ctrl is
	when EA_alu_ctrl_z 		=> ea_N_tmp <= (others => '0');
	when EA_alu_ctrl_m1 		=> ea_N_tmp <= (others => '1');
	when EA_alu_ctrl_delta 	=> ea_N_tmp <= delta;
	when EA_alu_ctrl_ndelta => ea_N_tmp <= NOT delta;
	when others 				=> ea_N_tmp <= NOT delta;
end case;
end process;
--			EA adder
EA_tmp <= EAreg_tmp + ea_N_tmp + ea_alu_cin;	-- effective address (EA) adder


--						SPn, EAW generate
--			SPn mux
SPn_ctrl <= L;
process(sp0,sp1,sp2,sp3,SPn_ctrl)			-- 4:1 muxing of SP[L], generates QPM port B address
begin
case SPn_ctrl is
	when SPn_ctrl_SP0 => SPn_tmp <= "0000" & sp0;
	when SPn_ctrl_SP1 => SPn_tmp <= "0000" & sp1;
	when SPn_ctrl_SP2 => SPn_tmp <= "0000" & sp2;
	when SPn_ctrl_SP3 => SPn_tmp <= "0000" & sp3;
	when others			=> SPn_tmp <= "0000" & sp3;
end case;
end process;
--			EA/SPn mux
process(SPn_tmp, EA_tmp, EAW_sel)
begin
case EAW_sel is
	when EAW_sel_SPn => EAW_alu_tmp <= SPn_tmp;
	when EAW_sel_EA  => EAW_alu_tmp <= EA_tmp;
	when others		  => EAW_alu_tmp <= EA_tmp;
end case;
end process;
--			EAW adder
EAW_tmp <= EAW_alu_tmp + (EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&
		EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1&EAW_m1) + EAW_cin;
MDadr <= EAW_tmp(10 downto 0);

--							Update values & muxes for FP, TP, SP0...3
process(fptp_ctrl,EA_tmp,SPnp1_tmp)	-- FP & TP update mux
begin
case fptp_ctrl is
	when fptp_ctrl_EA		=>	ptr_tmp <= EA_tmp;
	when others				=> ptr_tmp <= SPnp1_tmp;
end case;
end process;
process(SP0_ctrl,EA_tmp,SPnp1_tmp)	-- SP0 update mux
begin
case SP0_ctrl is
	when SP0_ctrl_EA		=>	ptr_tmp <= EA_tmp;
	when others				=> ptr_tmp <= SPnp1_tmp;
end case;
end process;
process(SP1_ctrl,EA_tmp,SPnp1_tmp)	-- SP0 update mux
begin
case SP1_ctrl is
	when SP1_ctrl_EA		=>	ptr_tmp <= EA_tmp;
	when others				=> ptr_tmp <= SPnp1_tmp;
end case;
end process;
process(SP2_ctrl,EA_tmp,SPnp1_tmp)	-- SP0 update mux
begin
case SP2_ctrl is
	when SP2_ctrl_EA		=>	ptr_tmp <= EA_tmp;
	when others				=> ptr_tmp <= SPnp1_tmp;
end case;
end process;
process(SP3_ctrl,EA_tmp,SPnp1_tmp)	-- SP0 update mux
begin
case SP3_ctrl is
	when SP3_ctrl_EA		=>	ptr_tmp <= EA_tmp;
	when others				=> ptr_tmp <= SPnp1_tmp;
end case;
end process;


--						PC generate
--			PC adder
process(PCp1_ctrl,PC,NN)
begin
case PCp1_ctrl is
	when PCp1_ctrl_PCp0	=> NN_tmp <= (others => '0');
	when PCp1_ctrl_PCpN	=> NN_tmp <= NN(11 downto 0);
	when others 			=> NN_tmp <= NN(11 downto 0);
end case;
end process;
--			PC adder
PCp1_tmp <= "0000" & (PC + NN_tmp + PC_cbit);

--			PC register input mux
process(MDO,PCp1_tmp,SPn_tmp,EA_tmp,pc_ctrl)
begin
case pc_ctrl is
	when PC_ctrl_EA   => PC_tmp <= EA_tmp;
	when PC_ctrl_SPn  => PC_tmp <= SPn_tmp;
	when PC_ctrl_PCp1 => PC_tmp <= PCp1_tmp;
	when PC_ctrl_MDO  => PC_tmp <= MDO;
	when others 		=> PC_tmp <= MDO;
end case;
end process;
PCx <= PC_tmp(11 downto 0);
IRadr <= PC_tmp(9 downto 0);


--						Phase 2 main ALU data path
--		condition coder register carry mux
process(C,L)											-- carry CCR bit select
begin
case L is
	when SPn_ctrl_SP0 => c_tmp <= C(0);
	when SPn_ctrl_SP1 => c_tmp <= C(1);
	when SPn_ctrl_SP2 => c_tmp <= C(2);
	when SPn_ctrl_SP3 => c_tmp <= C(3);
	when others			=> c_tmp <= C(3);
end case;
end process;
--		ALU carry input mux
process(c_tmp,cin_ctrl)									-- ALU carry in select
begin
case cin_ctrl(1) is
	when cin_ctrl_0	=> ccr_tmp <= '0';
	when others			=> ccr_tmp <= c_tmp;
end case;
end process;
--		complement carry for subtract
process(ccr_tmp,m)
begin
case cin_ctrl(0) is
	when '0' 	=> cin_tmp <= ccr_tmp;
	when others => cin_tmp <= not ccr_tmp;
end case;
end process;
--		2nd operand MUX (IR2, CCR & IO inputs), for Phase 2
process(IR,CCR,IOin,N,alusmux_ctrl)	-- 2nd operand MUX
begin
case alusmux_ctrl is
	when "000" => opnd2_tmp <= IOin(15 downto 0);
	when "001" => opnd2_tmp <= IOin(31 downto 16);
	when "010" => opnd2_tmp <= CCR(15 downto 0);
	when "011" => opnd2_tmp <= CCR(31 downto 16);
--	when "100" => opnd2_tmp <= IR(15 downto 0);
	when "101" => opnd2_tmp <= IR(31 downto 16);
	when "110" => opnd2_tmp <= (others => '0');
	when others => opnd2_tmp <= IR(15 downto 0);
end case;
end process;
--			Boolean LU
process(MDO,opnd2_tmp,bool_ctrl)								-- Boolean operations select
begin
case bool_ctrl(2 downto 0) is
	when bool_ctrl_z 			=> bool_tmp <= (others => '0');
	when bool_ctrl_nMDO		=> bool_tmp <= not MDO;
	when bool_ctrl_1and2 	=> bool_tmp <= opnd2_tmp and MDO;
	when bool_ctrl_1andn2	=> bool_tmp <= opnd2_tmp and not MDO;
	when bool_ctrl_n1and2	=> bool_tmp <= not opnd2_tmp and MDO;
	when bool_ctrl_1or2 		=> bool_tmp <= opnd2_tmp or MDO;
	when bool_ctrl_1xor2 	=> bool_tmp <= opnd2_tmp xor MDO;
	when others 				=> bool_tmp <= MDO;
end case;
end process;
--			Complement opnd2_tmp
process(opnd2_tmp,alu_op)
begin
case alu_op(0) is
	when '0' => comp_tmp <= opnd2_tmp;
	when others => comp_tmp <= not opnd2_tmp;
end case;
end process;
--	adder with logic inputs
ALU_tmp <= ('0' & comp_tmp) + ('0' & bool_tmp) + cin_tmp;
-- signed multiplier
mult_tmp <= signed(multsigns(0) & MDO) * signed(multsigns(1) & opnd2_tmp);
--			ALU output/MDI mux
process(ALU_tmp,mult_tmp,CCR,outmx_ctrl)
begin
case outmx_ctrl is
	when "000" => alu_result <= ALU_tmp(15 downto 0);
	when "001" => alu_result <= SPn;
	when "010" => alu_result <= mult_tmp(15 downto 0);
	when "011" => alu_result <= mult_tmp(31 downto 16);
	when "100" => alu_result <= FP;
	when "101" => alu_result <= TP;
	when "110" => alu_result <= PCp1;
	when others => alu_result <= EA;
end case;
end process;
MDI <= alu_result;


end Behavioral;

