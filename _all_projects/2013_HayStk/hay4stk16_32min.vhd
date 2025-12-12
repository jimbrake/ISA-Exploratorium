----------------------------------------------------------------------------------
--	hay4stk16_32min 	Quad stack processor with 16-bit data and 32-bit instructions, minimal instruction set
-- Company: 		Brakefield Research
-- Engineer:		James C. Brakefield
-- 
-- Create Date:    18:53:54 05/19/2014 
-- Design Name: 	 hay4stk16_32min
-- Module Name:    hay4stk16_32min - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		Quad stack processor with 16-bit data and 32-bit instructions, minimal instruction set
--		Two/four stage pipe:
--		state 1: read and register next instruction and possibly write data to block RAM
--		state 2: decode instruction and/or perform instructions that take one memory cycle
--		state 3: read operands from block RAM
--		state 4: compute results; prepare to read next instruction, prepare write results and update registers
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;		-- xilinx IP
use UNISIM.VComponents.all;

entity hay4stk16_32min is
    Port ( clk : in  STD_LOGIC;
           input_sigs : in  STD_LOGIC_VECTOR (31 downto 0);
           out_sigs : out  STD_LOGIC_VECTOR (31 downto 0));
end hay4stk16_32min;

architecture Behavioral of hay4stk16_32min is

COMPONENT BUFG IS
  PORT (
     I      : IN STD_ULOGIC;
     O      : OUT STD_ULOGIC);
END COMPONENT;

COMPONENT dpRAM32n16 IS
  PORT (
      --Port A: 32-bit read only instruction & data port
    ENA            : IN STD_LOGIC;  --opt port
    WEA            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    ADDRA          : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    DINA           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    DOUTA          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    CLKA       : IN STD_LOGIC;
      --Port B: 16-bit read/write port
    ENB            : IN STD_LOGIC;  --opt port
    WEB            : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    ADDRB          : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    DINB           : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    DOUTB          : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    CLKB           : IN STD_LOGIC);
END COMPONENT dpRAM32n16;

COMPONENT  all_logic IS
  Port (
    pc :     in STD_LOGIC_VECTOR (11 downto 0);		-- program counter, low bit always zero
    pcx :   out STD_LOGIC_VECTOR (11 downto 0);		-- update value for PC
	 state :  in state_type;								-- current instruction processing state
	 statex :out state_type;								-- next instruction processing state
    tp :     in STD_LOGIC_VECTOR (11 downto 0);		-- Thread Pointer, low bit always zero
    fp :     in STD_LOGIC_VECTOR (11 downto 0);		-- Frame Pointer, low bit always zero
    tpfpx : out STD_LOGIC_VECTOR (11 downto 0);		-- update value for FP or TP
    sp0 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP0: first stack pointer, word addressing
    sp0x :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for SP0
    sp1 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP1: second stack pointer, word addressing
    sp1x :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for SP1
    sp2 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP2: third stack pointer, word addressing
    sp2x :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for SP2
    sp3 :    in STD_LOGIC_VECTOR (11 downto 0);		-- SP3: fourth stack pointer, word addressing
    sp3x :  out STD_LOGIC_VECTOR (11 downto 0);		-- update value for SP3
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
    ioout2_3:out STD_LOGIC_VECTOR(31 downto 0));	-- Output port 2 & 3 (locations -3 & -4), CCR is output ports 0 & 1 (locations -1 & -2)
END COMPONENT all_logic;

type state_type is (state1, state2, state3, state4); 
--		state 1: read and register next instruction and possibly write data to block RAM
--		state 2: decode instruction and/or perform instructions that take one memory cycle
--		state 3: read operands from block RAM
--		state 4: compute results; prepare to read next instruction, prepare write results and update registers

signal clk_buf: std_logic;								-- use global buffer for clock
signal we: 		std_logic_vector(0 downto 0);		-- MDO write enable
--		Register and RAM update enables, forwarded to regxe
signal pcxe: 	std_logic;								-- PC update enable
signal tpxe: 	std_logic;								-- thread pointer update enable
signal fpxe: 	std_logic;								-- frame pointer update enable
signal sp0xe: 	std_logic;								-- stack pointer 0 update enable
signal sp1xe: 	std_logic;								-- stack pointer 1 update enable
signal sp2xe: 	std_logic;								-- stack pointer 2 update enable
signal sp3xe: 	std_logic;								-- stack pointer 3 update enable
signal memwe: 	std_logic;								-- dual port RAM write enable
signal io2xe: 	std_logic;								-- IO port 2 write enable
signal PC_tmp: std_logic_vector(9 downto 0);		-- read address for next instruction or for stage 3 operand
signal IR_tmp: std_logic_vector(31 downto 0);	-- unclocked data out of block RAM
signal EAW_tmp:std_logic_vector(10 downto 0);	-- data port read/write address
signal MDI: 	std_logic_vector(15 downto 0);	-- data to be written to block RAM
signal MDO:		std_logic_vector(15 downto 0);	-- unclocked data out of block RAM
signal pcx:		STD_LOGIC_VECTOR(11 downto 0);	-- update value for PC
signal state:	STD_LOGIC;								-- current instruction processing state: Phase 0, 1 or 2
signal statex: STD_LOGIC;								-- next instruction processing state: Phase 0, 1 or 2
signal tp:     STD_LOGIC_VECTOR(11 downto 0);	-- Thread Pointer, low bit always zero
signal fp:     STD_LOGIC_VECTOR(11 downto 0);	-- Frame Pointer, low bit always zero
signal tpfpx:  STD_LOGIC_VECTOR(11 downto 0);	-- update value for FP or TP
signal sp0:    STD_LOGIC_VECTOR(11 downto 0);	-- SP0: first stack pointer, word addressing
signal sp1:    STD_LOGIC_VECTOR(11 downto 0);	-- SP1: second stack pointer, word addressing
signal sp2:    STD_LOGIC_VECTOR(11 downto 0);	-- SP2: third stack pointer, word addressing
signal sp3:    STD_LOGIC_VECTOR(11 downto 0);	-- SP3: fourth stack pointer, word addressing
signal spnx:   STD_LOGIC_VECTOR(11 downto 0);	-- update value for SPn
signal ccr:    STD_LOGIC_VECTOR(31 downto 0);	-- condition code register: C3-0, V3-0, Z3-0, MSB3-0, P3-0, LSB3-0, DD3-0, DSZ1-0, INTE, INTT 
signal ccrx:   STD_LOGIC_VECTOR(31 downto 0);	-- update values for CCR
signal IRadr:  STD_LOGIC_VECTOR(9 downto 0);		-- DP RAM port A address, instruction & data reads
signal MDadr:  STD_LOGIC_VECTOR(10 downto 0);	-- DP RAM port B address, data reads and data writes
signal ir:     STD_LOGIC_VECTOR(31 downto 0);	-- instruction "register", AKA DP RAM port A output value (dpdoa), 32-bits wide
signal ir2:    STD_LOGIC_VECTOR(31 downto 0);	-- registered IR for Phase2 & Phase3 processing
signal MDI:    STD_LOGIC_VECTOR(15 downto 0);	-- DP RAM port B data input
signal MDO:    STD_LOGIC_VECTOR(15 downto 0);	-- DP RAM port B output value, 16-bits wide
signal regxe:  STD_LOGIC_VECTOR(8 downto 0);		-- combined update enables and write enables
signal ccrxe:  STD_LOGIC_VECTOR(11 downto 0);	-- CCR update bit enables and nibble enables

begin

--		Register and RAM update enable subfields
--regxe <= io2xe & memwe & pcxe & tpxe & fpxe & sp3xe & sp2xe & sp1xe & sp0xe;
io2xe<=regxe(8); we<=regxe(7); pcxe<=regxe(6);
tpxe<=regxe(5); fpxe<=regxe(4);
sp3xe<=regxe(3); sp2xe<=regxe(2); sp1xe<=regxe(1); sp0xe<=regxe(0);

bufg_A : BUFG
    PORT MAP (I => clk, O => clk_buf);

bmg0 : dpRAM32n16
    PORT MAP (
      --Port A: 32-bit read only instruction & data port
      ENA        => '1',
      WEA        => "0",
      ADDRA      => PC_tmp(10 downto 1),
      DINA       => (others => '0'),
      DOUTA      => IR_tmp,
      CLKA       => clk_buf,
      --Port B: 16-bit read/write port
      ENB        => '1', 
      WEB        => we,
      ADDRB      => EAW_tmp,
      DINB       => MDI,
      DOUTB      => MDO,
      CLKB       => clk_buf);

logic :  all_logic
	 Port Map (
	   pc => PC,					-- program counter, low bit always zero
      pcx => PCx,					-- update value for PC
      state => state,			-- current instruction processing state
      statex => statex,			-- next instruction processing state
		tp => tp,					-- Thread Pointer, low bit always zero
		fp => fp,					-- Frame Pointer, low bit always zero
		tpfpx => tpfpx,			-- update value for FP or TP
		sp0 => sp0,					-- SP0: first stack pointer, word addressing
		sp1 => sp1,					-- SP1: second stack pointer, word addressing
		sp2 => sp2,					-- SP2: third stack pointer, word addressing
		sp3 => sp3,					-- SP3: fourth stack pointer, word addressing
		sp3x => spnx,				-- update value for SPn
		ccr => ccr,					-- condition code register: C3-0, V3-0, Z3-0, MSB3-0, P3-0, LSB3-0, DD3-0, DSZ1-0, INTE, INTT 
		ccrx => ccrx,				-- update values for CCR
		IRadr => IRadr, 			-- DP RAM port A address, instruction & data reads
		MDadr => MDadr, 			-- DP RAM port B address, data reads and data writes
		ir => ir,					-- instruction "register", AKA DP RAM port A output value (dpdoa), 32-bits wide
		ir2 => ir2,					-- registered IR for Phase2 & Phase3 processing
		MDI => MDI, 				-- DP RAM port B data input
		MDO => MDO, 				-- DP RAM port B output value, 16-bits wide
		regxe => regxe,			-- combined update enables and write enables
		ccrxe => ccrxe,			-- CCR update bit enables and nibble enables
		ioin2_3 => input_sigs,	-- Input ports 2 & 3 (locations -3 & -4), CCR is input ports 0 & 1 (locations -1 & -2)
		ioout2_3 => out_sigs);	-- Output port 2 & 3 (locations -3 & -4), CCR is output ports 0 & 1 (locations -1 & -2)

--					PC update
process(PCp1)			
begin
PC_tmp <= (others => '0');
if (rising_edge(clk_buf) and pcxe='1') then PC<=PCx; end if;
end process;

end Behavioral;

