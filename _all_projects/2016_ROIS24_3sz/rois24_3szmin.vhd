----------------------------------------------------------------------------------
-- Company:         Brakefield Research
-- Engineer:        James Brakefield
-- 
-- Create Date:     07/12/2025
-- Design Name:     rois24_3szmin
-- Project Name:    rois24_3sz
-- Target Devices:  Boolean Board
-- Tool versions:   Vivado 25.1 VHDL 2008
-- Description:     RISC processor with 24-bit registers
--      Byte addressing with load/store of 8, 16 and 24-bit data
--      Dual port block RAM for instructions and data, is 1024x16 with access to addressed location and location+2
--		Status register: carry, overflow, zero, sign and 4 others; seperate PC register
--		Register zero always reads as zero, can use subtact to reg zero as a compare instruction
--		Any load to register zero is a trap or other instruction (breakpoint, skip byte, etc)??
-- Revisions
--      01/22/2017  copied and renamed from rois24_24min project files
--      01/22/2017  allocation of load/store 8-bit and 16-bit data, both unsigned and signed
--      07/12/2025	rework into current practice: little endian, port mapped reg-file & main memory, etc.
--		07/12/2025	make op-code zero a trap instruction, add load & store float instructions
--      Hex instuction opcodes
-- 00 TRAP/LDF  01 STF      02 CALL     03 JMPCC        04 CALLR/BR/HLT 05 BRCC(NN) 06 LDSI(NN) 07 PFX (NNN)
-- 08 LDB       09 STB      0A LDH      0B STH          0C LDSB         0D LD       0E LDSH     0F ST
-- 10 LDBN      11 STBN     12 LDHN     13 STHN         14 LDSBN        15 unused   16 LDSHN    17 unused (N)
-- 18 LDN       19 STN      1A CALLN    1B JMPCCN/JMPN  1C INN          1D OUTN     1E unused   1F unused (N)
-- 20 ADD       21 SUB      22 ADC      23 SBC          24 AND          25 ANDC     26 OR       27 XOR
-- 28 MUL       29 MULU     2A MULUS    2B DIV          2C FADD         2D FSUB     2E FMUL     2F FDIV
-- 30 ADDI      31 SUBI     32 ADCI     33 SBCI         34 ANDI         35 ANDCI    36 ORI      37 XORI  (N)
-- 38 MULI      39 MULUI    3A MULUSI   3B DIVI         3C FADDI        3D FSUBI    3E FMUL     3F FDIVI (N)
--      Hex condition codes for BRCC(NN), JMPCC & JMPCCN(N)
-- 00 A         01 NOP      02 Z/EQ     03 NZ/NE        04 CS/LO        05 CC/HS    06 MI       07 PL
-- 08 VS        09 VC       0A LE       0B GT           0C GE           0D LT       0E LS       0F HI
-- 10 OD        11 EV       12 1        13 N1           14 M1           15 NM1      16 M2       17 NM2
-- 18 01        19 N01      1A 0M1      1B N0M1         1C 01M1         1D N01M1    1E 01M2     1F N01M2
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.numeric_std.all;
USE work.constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rois24_24 is Port (    -- 24-bit soft core processor using 64X24 LUTRAM for register file & 1KX24 block RAM for program
    CLOCK_Y3   : in STD_LOGIC;        -- master clock, fully synchronous design
----  Test bench signals
--    PC_tb      : out std_logic_vector(9 downto 0);  -- current instruction address/block RAM read/write address
--    inst_tb    : out std_logic_vector(23 downto 0); -- current instruction
--    dloc_tb    : out std_logic_vector(5 downto 0);  -- LUT ram write location
--    din_tb     : out std_logic_vector(23 downto 0); -- LUT ram write data
--    dout_tb    : out std_logic_vector(23 downto 0); -- LUT ram out, block RAM write data
--    dlocwe_tb  : out std_logic;                     -- LUT ram write enable
--    blkwe_tb   : out std_logic;                     -- block ram write enable
--    CCRN_tb    : out std_logic_vector(data_size+2 downto 0);    -- condition code register
--    state_tb   : out state_type;                    -- instruction processing state
    
--  # User Reset Push Button    # pushed = high!
    USER_RESET_N : in   STD_LOGIC:='0';  --SW5    LOC = V4  | IOSTANDARD = LVCMOS33 | PULLDOWN;    # "USER_RESET_N"
--  # User DIP Switch x4    # ON = high
    GPIO_DIP1    : in   STD_LOGIC:='0';  --SW1 #1 LOC = B3  | IOSTANDARD = LVCMOS33 | PULLDOWN;    # "GPIO_DIP1"
    GPIO_DIP2    : in   STD_LOGIC:='0';  --SW1 #2 LOC = A3  | IOSTANDARD = LVCMOS33 | PULLDOWN;    # "GPIO_DIP2"
    GPIO_DIP3    : in   STD_LOGIC:='0';  --SW1 #3 LOC = B4  | IOSTANDARD = LVCMOS33 | PULLDOWN;    # "GPIO_DIP3"
    GPIO_DIP4    : in   STD_LOGIC:='0';  --SW1 #4 LOC = A4  | IOSTANDARD = LVCMOS33 | PULLDOWN;    # "GPIO_DIP4"
--  # User LEDs             # high = lit, no series resistor!			
    GPIO_LED1  : out  STD_LOGIC;    --D2  LOC = P4  | IOSTANDARD = LVCMOS18;               # "GPIO_LED1"
    GPIO_LED2  : out  STD_LOGIC;    --D3  LOC = L6  | IOSTANDARD = LVCMOS18;               # "GPIO_LED2"
    GPIO_LED3  : out  STD_LOGIC;    --D9  LOC = F5  | IOSTANDARD = LVCMOS18;               # "GPIO_LED3"
    GPIO_LED4  : out  STD_LOGIC);   --D10 LOC = C2  | IOSTANDARD = LVCMOS18;               # "GPIO_LED4"
end rois24_24;

architecture RTL of rois24_24 is

signal state, stateN : state_type:=NORMst;  --  state variable for multiple clock instructions

--  LUT RAM signals
--signal opcode				 	: std_logic_vector(LUTRAM_adr_size-1 downto 0); -- opcode same size as register pointers
--signal Rrloc, Sloc, Tloc, Dloc  : std_logic_vector(LUTRAM_adr_size-1 downto 0); -- register location pointers AKA LUT RAM adrs
--signal dlocx                    : std_logic_vector(LUTRAM_adr_size-1 downto 0):=(OTHERS => '0'); -- registered dloc_inst
--signal dloc_inst                : std_logic_vector(LUTRAM_adr_size-1 downto 0); -- inst decode dloc
signal opcode				 	: unsigned(5 downto 0); -- opcode same size as register pointers
signal Rrloc, Sloc, Dloc        : unsigned(5 downto 0); -- register location pointers AKA LUT RAM adrs
signal dlocx                    : unsigned(5 downto 0):=(OTHERS => '0'); -- registered dloc_inst
signal dloc_inst                : unsigned(5 downto 0); -- inst decode dloc
signal R, S, Din, Dout          : unsigned(data_size-1 downto 0);       -- LUT RAM data ports
signal lutwe                    : std_logic;                                    -- quad port LUT RAM write enable
--      3R1RW port LUT RAM for register file
type lutRAM_type is array (LUTRAM_size-1 downto 0) of unsigned(data_size-1 downto 0);	-- register file type
signal lutRAM : lutRAM_type:=(others =>"000000000000000000000000");                             -- register file

--  block RAM signals
signal blkrdata                     : unsigned(data_size-1 downto 0);           -- block RAM read data
signal b,h                          : std_logic;                                        -- bits 7 and 15 of blkrdata
signal blkwdata                     : unsigned(data_size-1 downto 0);           -- block RAM write data
signal blkrdata0,blkrdata1,blkrdata2,blkrdata3  : unsigned(7 downto 0);         -- block RAM read data ports
signal blkwdata0,blkwdata1,blkwdata2,blkwdata3  : unsigned(7 downto 0);         -- block RAM write data ports
signal rwadr                        : unsigned(mem_adr_size-1 downto 0);        -- block RAM address
signal rwadr0,rwadr2                : unsigned(mem_adr_size-2 downto 0);        -- block RAM address ports
signal blkwe                        : unsigned(2 downto 0);                     -- write enables, one for each 8 of 24-bits
signal blkwe0,blkwe1,blkwe2,blkwe3  : std_logic;                                        -- block RAM write enables
signal mem1024x8a,mem1024x8b        : blkRAM_type;  --:=(                               -- dual port block RAM array
--		block RAM initialization, contains the program, UGH: for Spartan-6 need to NOT the address
--          ROIS24_24min full instruction set test bench
---- 0x00
--op_BR    & "000000" & "000000" & "000010",         -- branch over next instruction
--op_BR    & "000000" & "000000" & "000000",         -- loop forever, termination location for test bench
----          Conditional tests
---- 0x02
----op-code   D reg      R reg      S reg or signed constant
--op_ADDI  & "000011" & "000000" & "000000",         -- clear reg 3
--op_SUBI  & "000011" & "000011" & "000001",         -- subtract 1 from reg 3
--op_ADDI  & "000011" & "000011" & "000001",         -- add 1 to reg 3, will force carry and clear
--op_BRCC  &   cc_CS  & "000000" & "000010",op_HLT,  -- skip next inst if carry set
--op_BRCC  &    cc_Z  & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_BRCC  &   cc_PL  & "000000" & "000010",op_HLT,  -- skip next inst if MSB clear
--op_BRCC  &   cc_VC  & "000000" & "000010",op_HLT,  -- skip next inst if overflow clear
--op_BRCC  &   cc_LE  & "000000" & "000010",op_HLT,  -- skip next inst if less than or equal
--op_BRCC  &   cc_GE  & "000000" & "000010",op_HLT,  -- skip next inst if greater than or equal
--op_BRCC  &   cc_LS  & "000000" & "000010",op_HLT,  -- skip next inst if low same
--op_BRCC  &   cc_EV  & "000000" & "000010",op_HLT,  -- skip next inst if even
--op_BRCC  &   cc_N1  & "000000" & "000010",op_HLT,  -- skip next inst if not one
--op_BRCC  &  cc_NM1  & "000000" & "000010",op_HLT,  -- skip next inst if not -1
--op_BRCC  &  cc_NM2  & "000000" & "000010",op_HLT,  -- skip next inst if not -2
--op_BRCC  &   cc_01  & "000000" & "000010",op_HLT,  -- skip next inst if zero or one
--op_BRCC  &  cc_0M1  & "000000" & "000010",op_HLT,  -- skip next inst if zero or -1
--op_BRCC  & cc_01M1  & "000000" & "000010",op_HLT,  -- skip next inst if zero, one or -1
--op_BRCC  &cc_01M12  & "000000" & "000010",op_HLT,  -- skip next inst if zero, one, -1 or -2
----          Reverse conditional tests
---- 0x23
----op-code   D reg      R reg      S reg or signed constant
--op_SUBI  & "000011" & "000011" & "000011",         -- subtract 3 from reg 3
--op_ADDI  & "000011" & "000011" & "000000",         -- clear carry by adding zero
--op_BRCC  &   cc_CC  & "000000" & "000010",op_HLT,  -- loc 0x28 skip next inst if carry clear
--op_BRCC  &   cc_NZ  & "000000" & "000010",op_HLT,  -- loc 0x2a skip next inst if not zero
--op_BRCC  &   cc_MI  & "000000" & "000010",op_HLT,  -- loc 0x2c skip next inst if MSB set
--op_BRCC  &   cc_VC  & "000000" & "000010",op_HLT,  -- loc 0x2e skip next inst if overflow clear
--op_BRCC  &   cc_LE  & "000000" & "000010",op_HLT,  -- loc 0x30 skip next inst if less than or equal
--op_BRCC  &   cc_LT  & "000000" & "000010",op_HLT,  -- loc 0x32 skip next inst if less than
--op_BRCC  &   cc_HI  & "000000" & "000010",op_HLT,  -- loc 0x34 skip next inst if low same
--op_BRCC  &   cc_OD  & "000000" & "000010",op_HLT,  -- loc 0x36 skip next inst if odd
--op_BRCC  &   cc_N1  & "000000" & "000010",op_HLT,  -- loc 0x38 skip next inst if not one
--op_BRCC  &  cc_NM1  & "000000" & "000010",op_HLT,  -- loc 0x3a skip next inst if not -1
--op_BRCC  &  cc_NM2  & "000000" & "000010",op_HLT,  -- loc 0x3c skip next inst if not -2
--op_BRCC  &  cc_N01  & "000000" & "000010",op_HLT,  -- loc 0x3e skip next inst if not zero or one
--op_BRCC  & cc_N0M1  & "000000" & "000010",op_HLT,  -- loc 0x40 skip next inst if not zero or -1
--op_BRCC  &cc_N01M1  & "000000" & "000010",op_HLT,  -- loc 0x42 skip next inst if not zero, one or -1
--op_BRCC  &cc_N01M12 & "000000" & "000010",op_HLT,  -- loc 0x44 skip next inst if not zero, one, -1 or -2
----          Specific match tests
---- 0x41
----op-code   D reg      R reg      S reg or signed constant
--op_ADDI  & "000011" & "000000" & "000001",         -- set reg 3 to one
--op_BRCC  &    cc_1  & "000000" & "000010",op_HLT,  -- skip next inst if one
--op_SUBI  & "000011" & "000011" & "000010",         -- set to -1
--op_BRCC  &   cc_M1  & "000000" & "000010",op_HLT,  -- skip next inst if -1
--op_SUBI  & "000011" & "000011" & "000001",         -- set to -2
--op_BRCC  &   cc_M2  & "000000" & "000010",op_HLT,  -- skip next inst if -2
----          Logical connectives
---- 0x4c
--op_LDSI  & "000011" & "000000" & "000011",
--op_LDSI  & "000101" & "000000" & "000101",
--op_AND   & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000001",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_ANDC  & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000010",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_OR    & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000111",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_XOR   & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000110",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_ANDI  & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000001",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_ANDCI & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000010",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_ORI   & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000111",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_XORI  & "000100" & "000011" & "000101",
--op_XORI  & "000000" & "000100" & "000110",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
----          Miscelaneous
---- 0x6e
--op_LDSI  & "000010" & "000000" & "001111",
--op_OUTN  & "000000" & "000000" & "000000",         -- turn on LEDs
--op_LDI   & "000010" & "100000" & "111111",
--op_PFX   & "111111" & "111111" & "100000",         -- test PFX
--op_XORI  & "000000" & "000010" & "111111",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_PFX   & "111111" & "111111" & "100000",         -- test PFX
--op_SUBI  & "000000" & "000010" & "111111",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
----          Load/store (loads & stores into this code segment)
---- 0x79
----op-code   D reg      R reg      S reg or signed constant
--op_LDN   & "000001" & "000000" & "000100",         -- load location 0X4 to reg #1
--op_PFX   & op_ADDI  & "000011" & "000011",         -- comparison value
--op_XORI  & "000000" & "000001" & "000001",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_LDSI  & "000110" & "000001" & "111010",         -- load address of 0x7a
--op_LD    & "000001" & "000000" & "000110",         -- load location 0X7a to reg #1
--op_PFX   & op_PFX   & op_ADDI  & "000011",         -- comparison value
--op_XORI  & "000000" & "000001" & "000011",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
--op_STN   & "000001" & "000110" & "001011",         -- store inst at location 0X7a to next location
--op_HLT,                                            -- gets replaced by inst at 0x7a
--op_PFX   & op_PFX   & op_ADDI  & "000011",         -- comparison value
--op_XORI  & "000000" & "000001" & "000011",
--op_BRCC  &   cc_Z   & "000000" & "000010",op_HLT,  -- skip next inst if zero
---- 0x8a
--op_CALLN & "000100" & "000000" & "000001",         -- branch to loc 0x1, save PC+1 (0x4d) in reg 4
--op_JMPN  & "000000" & "000000" & "000001",         -- end of instruction test bench

----      Das blinking lights
---- 0x00
----op-code   D reg      R reg      S reg or signed constant
--op_BR    & "000000" & "000000" & "000001",  -- loc 0x0  branch to next instruction
--op_ADDI  & "000000" & "000100" & "000000",  -- loc 0x1  examine reg 4
--op_ADDI  & "000001" & "000001" & "010000",  -- loc 0x2  add 16 to reg 1
--op_ADCI  & "000010" & "000010" & "000000",  -- loc 0x3  add carry to reg 2
--op_OUT   & "000010" & "000000" & "000000",  -- loc 0x4  output reg 2
--op_JMPN  & "000000" & "000000" & "000001",

--OTHERS => "000000"                          -- load reg 0 with memory data at location 0
--);
--ATTRIBUTE ram_extract: string;
--ATTRIBUTE ram_extract OF mem1024x8a: SIGNAL IS "yes";
--ATTRIBUTE ram_extract OF mem1024x8b: SIGNAL IS "yes";
--ATTRIBUTE ram_style: string;
--ATTRIBUTE ram_style OF mem1024x8a: SIGNAL IS "block";
--ATTRIBUTE ram_style OF mem1024x8b: SIGNAL IS "block";

--	N suffix indicates new value, eg pc is current pc, pcN is new/next PC
signal pc               : unsigned(data_size-1 downto 0):=(OTHERS => '1');       -- program counter
signal pcN              : unsigned(data_size-1 downto 0);       -- next clock value of program counter
signal pcp1,pcpN        : unsigned(data_size-1 downto 0);       -- PC+1 and PC+sNN
signal pcwe             : std_logic;                                    -- PC update enable    
signal RR, SS, ALUout	: unsigned(data_size downto 0);         -- ALU inputs and output (so carry is captured)
signal adder, SSS   	: unsigned(data_size downto 0);         -- RR+SSS, SS or not SS
signal cry              : std_logic;                                    -- carry into adder
signal inst             : unsigned(data_size-1 downto 0);       -- current instruction (block RAM data output)
signal outwe            : std_logic;                                    -- enable for output port
--signal sN               : unsigned(data_size-1 downto 0);       -- 6-bit signed displacement embedded in instruction
signal sNN              : unsigned(data_size-1 downto 0);       -- 12-bit signed displacement embedded in instruction
signal in0              : unsigned(data_size-1 downto 0);	    -- input port zero
--signal out0             : unsigned(data_size-1 downto 0) :=(OTHERS => '0');	-- output port zero
signal out0             : unsigned(3 downto 0) :=(OTHERS => '0');	-- output port zero
--		reduced CCR is 8-bits: carry, overflow, MSB, exponent all 0s, exponent all 1s, mantissa all 0s, mantissa all 1s, LSB
--		reduced CCR used for interrupts, expanded CCR used after ALU to remove additional LUT delays
signal CCR              : unsigned(data_size+2 downto 0):=(OTHERS => '0');  -- CCR(23..0) ALU result, CCR(24) carry, CCR(26:25) ovfl: MSB of ALU inputs
signal CCRN             : unsigned(data_size+2 downto 0);       -- next CCR
signal CCRwe			: std_logic;									-- CCR write enable
signal cry_ovfl_we		: std_logic;									-- write enable for carry and overflow bits
signal BR_bit           : std_logic;                                    -- if = '1' take the conditional branch (Dloc even)
signal BR_rslt          : std_logic;                                    -- BR_bit XOR Dloc(0), for Dloc odd as well
signal exp1s,exp0s      : std_logic;                                    -- exponent bits (bits 22..17) all ones or all zeros
signal mant1s,mant0s    : std_logic;                                    -- mantissa bits (bits 16..1) all ones or all zeros
signal carry_bit, sign_bit, LSB_bit, zero_bit, ovfl_bit : std_logic;    --  carry bit is 24, MSB is 23, LSB is 0, overflow is 25 = 26 & /= MSB

--signal pfx_ctl          : std_logic;                                    -- concatenate prefix onto sN
signal pfx_st           : std_logic:='0';                               -- current prefix state
signal pfx_stn          : std_logic:='0';                               -- new prefix state
signal pfx_stne         : std_logic:='0';                               -- new prefix state enable
signal pfx_reg          : unsigned(17 downto 0):=(OTHERS => '0');   -- registered bits 17..0 of a previous instruction (NNN)

signal clk              : std_logic;                                    -- VHDL clock name

begin
----  Test bench signal assignments
--PC_tb<=PC(9 downto 0);
--inst_tb<=inst;
--dloc_tb<=dloc;
--dout_tb<=dout;
--din_tb<=din;
--dlocwe_tb<=LUTwe;
--CCRN_tb<=CCR;
--state_tb<=state;
--blkwe_tb<=blkwe;

--  misc signal assignments
clk<=CLOCK_Y3;
--		relay the output port to LEDs
GPIO_LED1<=out0(0);
GPIO_LED2<=out0(1);
GPIO_LED3<=out0(2);
GPIO_LED4<=out0(3);
--      concatenate the input port
in0      <= "0000000000000000000" & GPIO_DIP4 & GPIO_DIP3 & GPIO_DIP2 & GPIO_DIP1 & USER_RESET_N;  -- unbuffered and not debounced 
--sN		<=  "000000000000000000" & inst(5 downto 0);    -- extend 6-bit immediate
--		sign extend 12-bit immediate
sNN		<=inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&
			inst(11 downto 0);
--		parse the instruction
opcode	    <= inst(23 downto 18);
dloc_inst   <= inst(17 downto 12);
rrloc	    <= inst(11 downto  6);
sloc	    <= inst( 5 downto  0);
exp0s       <= '1' when CCR(22 downto 17)="000000" else '0';
exp1s       <= '1' when CCR(22 downto 17)="111111" else '0';
mant0s      <= '1' when CCR(16 downto 1)="0000000000000000" else '0';
mant1s      <= '1' when CCR(16 downto 1)="1111111111111111" else '0';
carry_bit   <= CCR(24);
sign_bit    <= CCR(23);
LSB_bit     <= CCR(0);
zero_bit    <= '1' when CCR(23 downto 0)="0000000000000000000000000" else '0';
ovfl_bit    <= '1' when (CCR(25) = CCR(26)) AND (CCR(23) /= CCR(25)) else '0';

--      2R1RW port LUT ram for register file
process (clk)
begin
if rising_edge(clk) then
if (LUTwe = '1') then
    lutRAM(to_integer(dloc(LUTRAM_adr_size-1 downto 0))) <= Din;
end if;
end if;
end process;
R    <= lutRAM(to_integer(rrloc(LUTRAM_adr_size-1 downto 0)));
S    <= lutRAM(to_integer(sloc(LUTRAM_adr_size-1 downto 0)));
Dout <= lutRAM(to_integer(dloc(LUTRAM_adr_size-1 downto 0)));

--      main memory (both program and data) implemented in dual port block RAM
--			Inferred single port block RAM (LUT RAM used if address is 6-bits or less)
blkRAMa: process (clk)
begin
if rising_edge(clk) then
    if blkwe0 = '1' then mem1024x8a(to_integer(rwadr0)) <= blkwdata0;
                    else blkrdata0 <= mem1024x8a(to_integer(rwadr0));
                    end if;
    if blkwe2 = '1' then mem1024x8a(to_integer(rwadr2)) <= blkwdata2;
                    else blkrdata2 <= mem1024x8a(to_integer(rwadr2));
                    end if;
    end if;
--if (clk'event and clk = '1') then
--    blkrdata0 <= mem1024x8a(to_integer(rwadr0));
--    blkrdata2 <= mem1024x8a(to_integer(rwadr2));
--    if blkwe0 = '1' then
--        mem1024x8a(to_integer(rwadr0)) <= blkwdata0;
--    end if;
--    if blkwe2 = '1' then
--        mem1024x8a(to_integer(rwadr2)) <= blkwdata2;
--    end if;
--end if;
end process;
blkRAMb: process (clk)
begin
if rising_edge(clk) then
    if blkwe1 = '1' then mem1024x8b(to_integer(rwadr0)) <= blkwdata1;
                    else blkrdata1 <= mem1024x8b(to_integer(rwadr0));
                    end if;
    if blkwe3 = '1' then mem1024x8b(to_integer(rwadr2)) <= blkwdata3;
                    else blkrdata3 <= mem1024x8b(to_integer(rwadr2));
                    end if;
    end if;
--if (clk'event and clk = '1') then
--    blkrdata1 <= mem1024x8b(to_integer(rwadr0));
--    blkrdata3 <= mem1024x8b(to_integer(rwadr2));
--    if blkwe1 = '1' then
--        mem1024x8b(to_integer(rwadr0)) <= blkwdata1;
--    end if;
--    if blkwe3 = '1' then
--        mem1024x8b(to_integer(rwadr2)) <= blkwdata3;
--    end if;
--end if;
end process;

rwadr	<= pcN(mem_adr_size-1 downto 0);
rwadr0	<= not (rwadr(mem_adr_size-1 downto 1));        -- Spartan-6 hack
rwadr2	<= not (rwadr(mem_adr_size-1 downto 1) + 1);    -- Spartan-6 hack

blkrdata  <= blkrdata2 & blkrdata1 & blkrdata0 when rwadr(0) = '0' else blkrdata3 & blkrdata2 & blkrdata1;
inst	  <= blkrdata;
b         <= blkrdata(7);
h         <= blkrdata(15);
blkwdata  <= Dout;
blkwdata0 <= blkwdata( 7 downto  0);
blkwdata1 <= blkwdata(15 downto  8) when rwadr(0) = '0' else blkwdata( 7 downto 0);
blkwdata2 <= blkwdata(23 downto 16) when rwadr(0) = '0' else blkwdata(15 downto 8);
blkwdata3 <= blkwdata(23 downto 16);

blkwe0  <= blkwe(0) when rwadr(0) = '0' else '0';
blkwe1  <= blkwe(1) when rwadr(0) = '0' else blkwe(0);
blkwe2  <= blkwe(2) when rwadr(0) = '0' else blkwe(1);
blkwe3  <= '0'      when rwadr(0) = '0' else blkwe(2);

pcp1    <= PC+3;
pcpN    <= PC+sNN;
adder   <= RR + SSS + cry;
--      instruction decode and implementation
decode: process(all)
begin
--		default signal values
pcN<=pcp1; pcwe<='1'; outwe<='0'; ALUout<=adder; LUTwe<='0'; CCRwe<='0'; cry_ovfl_we<='0';
RR<= '0'&R; pfx_stn<='0'; pfx_stne<='0'; cry<='0'; 
Din<= ALUout(data_size-1 downto 0); 
blkwe<="000"; stateN<=NORMst; SS<='0'&S; 
dloc<=dloc_inst;
--      prefix treatment
if opcode(4)='1' then SS <= '0' & pfx_reg & sloc; end if; SSS<=SS;
if opcode(4)='1' and pfx_st='1' then pfx_stne<='1'; end if;  -- use prefix if sN instruction
--      instruction processing states
case state is
when LDst   => ALUout<='0'&blkrdata;                                LUTwe<='1'; dloc<=dlocx;-- 2nd cycle of Mem read
when LDBst  => ALUout<='0'&"0000000000000000"&blkrdata(7 downto 0); LUTwe<='1'; dloc<=dlocx;-- 2nd cycle of B Mem read
when LDSBst => ALUout<='0'&b&b&b&b&b&b&b&b&b&b&b&b&b&b&b&b&blkrdata(7 downto 0);LUTwe<='1'; dloc<=dlocx;-- 2nd cycle of SB Mem read
when LDHst  => ALUout<='0'&"00000000"&blkrdata(15 downto 0);        LUTwe<='1'; dloc<=dlocx;-- 2nd cycle of H Mem read
when LDSHst => ALUout<='0'&h&h&h&h&h&h&h&h&blkrdata(15 downto 0);   LUTwe<='1'; dloc<=dlocx;-- 2nd cycle of SH Mem read

when STst   => null;                                                             -- 2nd cycle of Mem write

when NORMst =>                                                                   -- normal instruction cycle
--		instruction implementation (for each instruction specify non-default signal values)
    case opcode is
        when op_SUB | op_SUBI | op_SBC | op_SBCI => SSS <= not SS;  -- complement SS for subtract type instructions
        when others => null;
    end case;
    case opcode is
        when op_ADD   | op_ADDI     =>  		    	                         LUTwe<='1'; CCRwe<='1'; cry_ovfl_we<='1';
        when op_ADC   | op_ADCI     =>               cry<=CCR(24);               LUTwe<='1'; CCRwe<='1'; cry_ovfl_we<='1';
        when op_SUB   | op_SUBI     =>               cry<='1'; 	                 LUTwe<='1'; CCRwe<='1'; cry_ovfl_we<='1';
        when op_SBC   | op_SBCI     =>               cry<=CCR(24);               LUTwe<='1'; CCRwe<='1'; cry_ovfl_we<='1';
        when op_AND   | op_ANDI     => ALUout<=RR and SS; 		                 LUTwe<='1'; CCRwe<='1';
        when op_ANDC  | op_ANDCI    => ALUout<=RR and (not SS); 	             LUTwe<='1'; CCRwe<='1';
        when op_OR    | op_ORI      => ALUout<=RR or SS; 			             LUTwe<='1'; CCRwe<='1';
        when op_XOR   | op_XORI     => ALUout<=RR xor SS; 			             LUTwe<='1'; CCRwe<='1';
        when op_LDB   | op_LDBN     =>                  pcN<=adder(23 downto 0);               stateN<=LDBst; pcwe<='0';
        when op_STB   | op_STBN     =>                  pcN<=adder(23 downto 0); blkwe<="001"; stateN<=STst; pcwe<='0';
        when op_LDH   | op_LDHN     =>                  pcN<=adder(23 downto 0);               stateN<=LDHst; pcwe<='0';
        when op_STH   | op_STHN     =>                  pcN<=adder(23 downto 0); blkwe<="011"; stateN<=STst; pcwe<='0';
        when op_LDSB  | op_LDSBN    =>                  pcN<=adder(23 downto 0);               stateN<=LDSBst; pcwe<='0';
        when op_LDSH  | op_LDSHN    =>                  pcN<=adder(23 downto 0);               stateN<=LDSHst; pcwe<='0';
        when op_LD    | op_LDN      =>                  pcN<=adder(23 downto 0);               stateN<=LDst; pcwe<='0';
        when op_ST    | op_STN      =>                  pcN<=adder(23 downto 0); blkwe<="111"; stateN<=STst; pcwe<='0';
        when op_CALL  | op_CALLN    => Din<=pcp1;       pcN<=adder(23 downto 0); LUTwe<='1';
        when op_JMPCC | op_JMPCCN   => if br_rslt='1' then pcN<=adder(23 downto 0);   end if;
        when op_LDSI                => ALUout<='0'&sNN;                          LUTwe<='1';
        when op_CALLR               => Din<=pcp1; pcN<=pcpN;                     LUTwe<='1';
        when op_BRCC                => if br_rslt='1' then pcN<=pcpN;                 end if;
        when op_PFX                 => pfx_stn<='1';  pfx_stne<='1';
        when op_INN                 => Din<=in0;                                 LUTwe<='1';	-- for now only one input port
        when op_OUTN                =>                                           outwe<='1';	-- for now only one output port
        when others => null;		        -- branch to next instruction (NOP)
--        when op_MUL   | op_MULI   -- requires multiplier (25x25)
--        when op_MULU  | op_MULUI  -- requires multiplier (25x25)
--        when op_MULUS | op_MULUSI -- requires multiplier (25x25)
--        when others => pcN<=('0'&pc);		-- effectively a branch to itself, eg HALT
    end case;       -- op-code decode & evaluate case statement

when others => null;
end case;       -- state variable case statement

CCRN <= RR(23) & SSS(23) & ALUout; -- need to set overflow bits to MSBs of adder inputs
if Dloc = "000000" then LUTwe<='0'; end if;		-- inhibit writes to register zero
end process;

--      condition code evalutation
CC_eval: process(Dloc,zero_bit,carry_bit,sign_bit,ovfl_bit,LSB_bit,exp0s,exp1s,mant0s,mant1s,br_bit)
begin
br_bit<='0';
case Dloc(5 downto 1) is
--    when cc_A(5 downto 1)   => br_bit<='1';
    when cc_Z(5 downto 1)   => if zero_bit = '1'                    then br_bit<='1'; end if;
    when cc_CS(5 downto 1)  => if carry_bit = '1'                   then br_bit<='1'; end if;
    when cc_MI(5 downto 1)  => if sign_bit = '1'                    then br_bit<='1'; end if;
    when cc_VS(5 downto 1)  => if ovfl_bit = '1'                    then br_bit<='1'; end if;
    when cc_LE(5 downto 1)  => if zero_bit = '1' OR sign_bit = '1'  then br_bit<='1'; end if;   -- PDP11 uses overflow bit: Z or (N xor V)=1
    when cc_GE(5 downto 1)  => if sign_bit = '0'                    then br_bit<='1'; end if;   -- PDP11 uses overflow bit: N xor V =0
    when cc_LS(5 downto 1)  => if carry_bit = '1' OR zero_bit = '1' then br_bit<='1'; end if;
    when cc_OD(5 downto 1)  => if LSB_bit = '1'                     then br_bit<='1'; end if;
    when cc_1(5 downto 1)   => if sign_bit = '0' AND exp0s = '1' AND mant0s = '1' AND LSB_bit = '1' then br_bit<='1'; end if;
    when cc_M1(5 downto 1)  => if sign_bit = '1' AND exp1s = '1' AND mant1s = '1' AND LSB_bit = '1' then br_bit<='1'; end if;
    when cc_M2(5 downto 1)  => if sign_bit = '1' AND exp1s = '1' AND mant1s = '1' AND LSB_bit = '0' then br_bit<='1'; end if;
    when cc_01(5 downto 1)  => if sign_bit = '0' AND exp0s = '1' AND mant0s = '1'                   then br_bit<='1'; end if;
    when cc_0M1(5 downto 1) => if zero_bit = '1' OR 
                                (sign_bit = '1' AND exp1s = '1' AND mant1s = '1' AND LSB_bit = '1') then br_bit<='1'; end if;
    when cc_01M1(5 downto 1)=> if (sign_bit = '0' AND exp0s = '1' AND mant0s = '1') OR 
                                (sign_bit = '1' AND exp1s = '1' AND mant1s = '1' AND LSB_bit = '1') then br_bit<='1'; end if;
    when cc_01M12(5 downto 1)=>if (sign_bit = '0' AND exp0s = '1' AND mant0s = '1') OR
                                (sign_bit = '1' AND exp1s = '1' AND mant1s = '1')                   then br_bit<='1'; end if;
    when others             => br_bit<='0';
end case;
br_rslt<=br_bit xor Dloc(0);        -- Dloc LSB inverts branch condition
end process;

--      registers and state update
update: process(clk)
begin
if (rising_edge(clk)) then
    state<=stateN;
    if pcwe = '1'           then pc<=pcN(23 downto 0);  end if; 
    if CCRwe = '1'          then CCR(23 downto 0)<=CCRN(23 downto 0); end if;
    if cry_ovfl_we = '1'    then CCR(26 downto 24)<=CCRN(26 downto 24); end if;     -- for overflow and carry bits
    if outwe = '1'          then out0<=Dout(3 downto 0); end if;		            -- for now only one output port
    if pfx_stne = '1'       then pfx_st<=pfx_stn; end if;                           -- update prefix state 
    if pfx_stne = '1'       then
        if pfx_stn='0' then pfx_reg<=(others => '0'); else pfx_reg<=inst(17 downto 0); end if; -- update prefix register
        end if;
    if pcwe = '0'           then dlocx<=dloc_inst; end if;      -- save dloc_inst if next cycle is read or write block RAM
end if;
end process;

end RTL;

