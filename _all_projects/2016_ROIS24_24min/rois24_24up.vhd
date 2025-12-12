----------------------------------------------------------------------------------
-- Company:         Brakefield Research
-- Engineer:        James Brakefield
-- 
-- Create Date:     03/06/2016 
-- Design Name:     rois24_24uP
-- Project Name:    rois24_24up_s6_bram2
-- Target Devices:  spartan 6 speed grade 3
-- Tool versions:   ISE 14.7
-- Description:     RISC processor with 24-bit registers and addressing
--
-- Dependencies:    full instruction set sans multiply, divide & floating-point
--
-- Revision:        0.01.01 
-- Revision 0.01 - File Created
-- 03/08/16 inferred data path & all instructions coded
-- 03/26/16 ALUout default changed from zero to "adder", blinking light loop runs
-- 03/27/16 coded rest of condition codes
-- Additional Comments:
--      rwadr negated to get block RAM initialization to work
--      program execution starts at location 1
--      Uses "inferred" data path, e.g., each unique adder is described: PC+1, PC+sNN, R+(S or pfx_reg & N)+carry-bit
--      One case entry for each instruction 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
USE work.constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity rois24_24up is Port (    -- 24-bit soft core processor using 64X24 LUTRAM for register file & 1KX24 block RAM for program
    CLOCK_Y3   : in STD_LOGIC;        -- master clock, fully synchronous design
    PC_tb      : out std_logic_vector(9 downto 0);
    inst_tb    : out std_logic_vector(23 downto 0);
    dloc_tb    : out std_logic_vector(5 downto 0);
    dlocwe_tb  : out std_logic;
    CCRN_tb    : out std_logic_vector(data_size+2 downto 0);
    state_tb   : out state_type;
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
end rois24_24up;

architecture RTL of rois24_24up is

signal state, stateN : state_type:=NORMst;  --  state variable for multiple clock instructions

--  LUT RAM signals
signal opcode				 	: std_logic_vector(LUTRAM_adr_size-1 downto 0); -- opcode same size as register pointers
signal Rrloc, Sloc, Tloc, Dloc  : std_logic_vector(LUTRAM_adr_size-1 downto 0); -- register location pointers AKA LUT RAM adrs
signal R, S, T, Din, Dout       : std_logic_vector(data_size-1 downto 0);       -- LUT RAM data ports
signal lutwe                    : std_logic;                                    -- quad port LUT RAM write enable

--  block RAM signals
signal blkrdata	                : std_logic_vector(data_size-1 downto 0):=(OTHERS => '0');  -- block RAM read data port
signal blkwdata	                : std_logic_vector(data_size-1 downto 0);                   -- block RAM write data port
signal rwadr                   	: std_logic_vector(mem_adr_size-1 downto 0);                -- block RAM address port
signal blkwe                    : std_logic;                                                -- block RAM write enable
signal mem512x24                : blkRAM_type:=(                                            -- single port block RAM array
--		block RAM initialization, contains the program, UGH: need to NOT the address
----       op-code   D reg    R reg    S reg or signed constant
--fmt_inst(op_CALLN, "000000","000000","000001"),
--fmt_inst(op_ADDI,  "000001","000001","000001"),
--fmt_inst(op_ADCI,  "000010","000010","000000"),
--fmt_inst(op_OUT,   "000010","000000","000000"),
--fmt_inst(op_CALLN, "000000","000000","000000"),
--op-code   D reg      R reg      S reg or signed constant
op_BR    & "000000" & "000000" & "000001",  -- loc 0x0  branch to next instruction
op_ADDI  & "000000" & "000100" & "000000",  -- loc 0x1  examine reg 4
op_ADDI  & "000001" & "000001" & "010000",  -- loc 0x2  add 16 to reg 1
op_ADCI  & "000010" & "000010" & "000000",  -- loc 0x3  add carry to reg 2
op_OUT   & "000010" & "000000" & "000000",  -- loc 0x4  output reg 2
--  conditional tests
--op-code   D reg      R reg      S reg or signed constant
op_ADDI  & "000011" & "000000" & "000000",  -- loc 0x5  clear reg 3
op_SUBI  & "000011" & "000011" & "000001",  -- loc 0x6  subtract 1 from reg 3
op_ADDI  & "000011" & "000011" & "000001",  -- loc 0x7  add 1 to reg 3, will force carry and clear
op_BRCC  &   cc_CS  & "000000" & "000010",  -- loc 0x8  skip next inst if carry set
op_BR    & "000000" & "000000" & "000000",  -- loc 0x9  halt
op_BRCC  &    cc_Z  & "000000" & "000010",  -- loc 0xa  skip next inst if zero
op_BR    & "000000" & "000000" & "000000",  -- loc 0xb  halt
op_BRCC  &   cc_PL  & "000000" & "000010",  -- loc 0xc  skip next inst if MSB clear
op_BR    & "000000" & "000000" & "000000",  -- loc 0xd  halt
op_BRCC  &   cc_VC  & "000000" & "000010",  -- loc 0xe  skip next inst if overflow clear
op_BR    & "000000" & "000000" & "000000",  -- loc 0xf  halt
op_BRCC  &   cc_LE  & "000000" & "000010",  -- loc 0x10 skip next inst if less than or equal
op_BR    & "000000" & "000000" & "000000",  -- loc 0x11 halt
op_BRCC  &   cc_GE  & "000000" & "000010",  -- loc 0x12 skip next inst if greater than or equal
op_BR    & "000000" & "000000" & "000000",  -- loc 0x13 halt
op_BRCC  &   cc_LS  & "000000" & "000010",  -- loc 0x14 skip next inst if low same
op_BR    & "000000" & "000000" & "000000",  -- loc 0x15 halt
op_BRCC  &   cc_EV  & "000000" & "000010",  -- loc 0x16 skip next inst if even
op_BR    & "000000" & "000000" & "000000",  -- loc 0x17 halt
op_BRCC  &   cc_N1  & "000000" & "000010",  -- loc 0x18 skip next inst if not one
op_BR    & "000000" & "000000" & "000000",  -- loc 0x19 halt
op_BRCC  &  cc_NM1  & "000000" & "000010",  -- loc 0x1a skip next inst if not -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x1b halt
op_BRCC  &  cc_NM2  & "000000" & "000010",  -- loc 0x1c skip next inst if not -2
op_BR    & "000000" & "000000" & "000000",  -- loc 0x1d halt
op_BRCC  &   cc_01  & "000000" & "000010",  -- loc 0x1e skip next inst if zero or one
op_BR    & "000000" & "000000" & "000000",  -- loc 0x1f halt
op_BRCC  &  cc_0M1  & "000000" & "000010",  -- loc 0x20 skip next inst if zero or -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x21 halt
op_BRCC  & cc_01M1  & "000000" & "000010",  -- loc 0x22 skip next inst if zero, one or -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x23 halt
op_BRCC  &cc_01M12  & "000000" & "000010",  -- loc 0x24 skip next inst if zero, one, -1 or -2
op_BR    & "000000" & "000000" & "000000",  -- loc 0x25 halt
--  reverse conditional tests
--op-code   D reg      R reg      S reg or signed constant
op_SUBI  & "000011" & "000011" & "000011",  -- loc 0x26 subtract 3 from reg 3
op_ADDI  & "000011" & "000011" & "000000",  -- loc 0x27 clear carry by adding zero
op_BRCC  &   cc_CC  & "000000" & "000010",  -- loc 0x28 skip next inst if carry clear
op_BR    & "000000" & "000000" & "000000",  -- loc 0x29 halt
op_BRCC  &   cc_NZ  & "000000" & "000010",  -- loc 0x2a skip next inst if not zero
op_BR    & "000000" & "000000" & "000000",  -- loc 0x2b halt
op_BRCC  &   cc_MI  & "000000" & "000010",  -- loc 0x2c skip next inst if MSB set
op_BR    & "000000" & "000000" & "000000",  -- loc 0x2d halt
op_BRCC  &   cc_VC  & "000000" & "000010",  -- loc 0x2e skip next inst if overflow clear
op_BR    & "000000" & "000000" & "000000",  -- loc 0x2f halt
op_BRCC  &   cc_LE  & "000000" & "000010",  -- loc 0x30 skip next inst if less than or equal
op_BR    & "000000" & "000000" & "000000",  -- loc 0x31 halt
op_BRCC  &   cc_LT  & "000000" & "000010",  -- loc 0x32 skip next inst if less than
op_BR    & "000000" & "000000" & "000000",  -- loc 0x33 halt
op_BRCC  &   cc_HI  & "000000" & "000010",  -- loc 0x34 skip next inst if low same
op_BR    & "000000" & "000000" & "000000",  -- loc 0x35 halt
op_BRCC  &   cc_OD  & "000000" & "000010",  -- loc 0x36 skip next inst if odd
op_BR    & "000000" & "000000" & "000000",  -- loc 0x37 halt
op_BRCC  &   cc_N1  & "000000" & "000010",  -- loc 0x38 skip next inst if not one
op_BR    & "000000" & "000000" & "000000",  -- loc 0x39 halt
op_BRCC  &  cc_NM1  & "000000" & "000010",  -- loc 0x3a skip next inst if not -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x3b halt
op_BRCC  &  cc_NM2  & "000000" & "000010",  -- loc 0x3c skip next inst if not -2
op_BR    & "000000" & "000000" & "000000",  -- loc 0x3d halt
op_BRCC  &  cc_N01  & "000000" & "000010",  -- loc 0x3e skip next inst if not zero or one
op_BR    & "000000" & "000000" & "000000",  -- loc 0x3f halt
op_BRCC  & cc_N0M1  & "000000" & "000010",  -- loc 0x40 skip next inst if not zero or -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x41 halt
op_BRCC  &cc_N01M1  & "000000" & "000010",  -- loc 0x42 skip next inst if not zero, one or -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x43 halt
op_BRCC  &cc_N01M12 & "000000" & "000010",  -- loc 0x44 skip next inst if not zero, one, -1 or -2
op_BR    & "000000" & "000000" & "000000",  -- loc 0x45 halt
--  specific match tests
op_ADDI  & "000011" & "000000" & "000001",  -- loc 0x46 set reg 3 to one
op_BRCC  &    cc_1  & "000000" & "000010",  -- loc 0x47 skip next inst if one
op_BR    & "000000" & "000000" & "000000",  -- loc 0x48 halt
op_SUBI  & "000011" & "000011" & "000010",  -- loc 0x49 set to -1
op_BRCC  &   cc_M1  & "000000" & "000010",  -- loc 0x4a skip next inst if -1
op_BR    & "000000" & "000000" & "000000",  -- loc 0x4b halt
op_SUBI  & "000011" & "000011" & "000001",  -- loc 0x4c set to -2
op_BRCC  &   cc_M2  & "000000" & "000010",  -- loc 0x4d skip next inst if -2
op_BR    & "000000" & "000000" & "000000",  -- loc 0x4e halt
op_CALLN & "000100" & "000000" & "000001",  -- loc 0x4f branch to loc 0x1, save PC+1 in reg 4
OTHERS => op_BR     & "000000" & "000000" & "000001" -- branch to next instruction
);

--	N suffix indicates new value, eg pc is current pc, pcN is new/next PC
signal pc               : std_logic_vector(data_size-1 downto 0):=(OTHERS => '0');       -- program counter
signal pcN              : std_logic_vector(data_size-1 downto 0);       -- next clock value of program counter
signal pcp1,pcpN        : std_logic_vector(data_size-1 downto 0);       -- PC+1 and PC+sNN
signal pcwe             : std_logic;                                    -- PC update enable    
signal RR, SS, ALUout	: std_logic_vector(data_size downto 0);         -- ALU inputs and output (so carry is captured)
signal adder, SSS   	: std_logic_vector(data_size downto 0);         -- RR+SSS, SS or not SS
signal cry              : std_logic;                                    -- carry into adder
signal inst             : std_logic_vector(data_size-1 downto 0);       -- current instruction (block RAM data output)
signal outwe            : std_logic;                                    -- enable for output port
--signal sN               : std_logic_vector(data_size-1 downto 0);       -- 6-bit signed displacement embedded in instruction
signal sNN              : std_logic_vector(data_size-1 downto 0);       -- 12-bit signed displacement embedded in instruction
signal in0              : std_logic_vector(data_size-1 downto 0);	    -- input port zero
signal out0             : std_logic_vector(data_size-1 downto 0) :=(OTHERS => '0');	-- output port zero
--		reduced CCR is 8-bits: carry, overflow, MSB, exponent all 0s, exponent all 1s, mantissa all 0s, mantissa all 1s, LSB
--		reduced CCR used for interrupts, expanded CCR used after ALU to remove additional LUT delays
signal CCR              : std_logic_vector(data_size+2 downto 0):=(OTHERS => '0');  -- CCR(23..0) ALU result, CCR(24) carry, CCR(26:25) ovfl: MSB of ALU inputs
signal CCRN             : std_logic_vector(data_size+2 downto 0);       -- next CCR
signal CCRwe			: std_logic;									-- CCR write enable
signal cry_ovfl_we		: std_logic;									-- write enable for carry and overflow bits
signal BR_bit           : std_logic;                                    -- if = '1' take the conditional branch (Dloc even)
signal BR_rslt          : std_logic;                                    -- BR_bit XOR Dloc(0), for Dloc odd as well
signal exp1s,exp0s      : std_logic;                                    -- exponent bits (bits 22..17) all ones or all zeros
signal mant1s,mant0s    : std_logic;                                    -- mantissa bits (bits 16..1) all ones or all zeros
signal carry_bit, sign_bit, LSB_bit, zero_bit, ovfl_bit : std_logic;    --  carry bit is 24, MSB is 23, LSB is 0, overflow is 25 = 26 & /= MSB

signal pfx_ctl          : std_logic;                                    -- concatenate prefix onto sN
signal pfx_st           : std_logic:='0';                               -- current prefix state
signal pfx_stn          : std_logic:='0';                               -- new prefix state
signal pfx_stne         : std_logic:='0';                               -- new prefix state enable
signal pfx_reg          : std_logic_vector(17 downto 0):=(OTHERS => '0');   -- registered bits 17..0 of a previous instruction (NNN)

signal clk              : std_logic;                                    -- VHDL clock name

begin
--  Test bench signal assignments
PC_tb<=PC(9 downto 0);
inst_tb<=inst;
dloc_tb<=dloc;
dlocwe_tb<=LUTwe;
CCRN_tb<=CCR;
state_tb<=state;

--  misc signal assignments
clk<=CLOCK_Y3;
--		relay the output port to LEDs
GPIO_LED1<=out0(0);
GPIO_LED2<=out0(1);
GPIO_LED3<=out0(2);
GPIO_LED4<=out0(3);
--      concatenate the input port
in0      <= "0000000000000000000" & GPIO_DIP4 & GPIO_DIP3 & GPIO_DIP2 & GPIO_DIP1 & USER_RESET_N;  -- unbuffered and not debounced 
----		extend 6-bit immediate
--sN		<=  "000000000000000000" & inst(5 downto 0);
--		sign extend 12-bit immediate
sNN		<=inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&inst(11)&
			inst(11 downto 0);
--		parse the instruction
opcode	<= inst(23 downto 18);
dloc	<= inst(17 downto 12);
rrloc	<= inst(11 downto  6);
sloc	<= inst( 5 downto  0);
tloc	<= "000000";
exp0s       <= '1' when CCR(22 downto 17)="000000" else '0';
exp1s       <= '1' when CCR(22 downto 17)="111111" else '0';
mant0s      <= '1' when CCR(16 downto 1)="0000000000000000" else '0';
mant1s      <= '1' when CCR(16 downto 1)="1111111111111111" else '0';
carry_bit   <= CCR(24);
sign_bit    <= CCR(23);
LSB_bit     <= CCR(0);
zero_bit    <= '1' when CCR(23 downto 0)="0000000000000000000000000" else '0';
ovfl_bit    <= '1' when (CCR(25) = CCR(26)) AND (CCR(23) /= CCR(25)) else '0';

--      64X24 quad port LUT RAM for register file
LUTRAM_generate: for i in 0 to data_size-1 generate
begin
--      register file implemented in a single quad port LUT RAM
   -- RAM64M: 64-deep by 1-wide Multi Port LUT RAM (Mapped to four SliceM LUT6s) 
   --         Kintex-7
   -- Xilinx HDL Language Template, version 14.7
   RAM64M_inst : RAM64M
   generic map (
      INIT_A => X"0000000000000000",   -- Initial contents of A port
      INIT_B => X"0000000000000000",   -- Initial contents of B port
      INIT_C => X"0000000000000000",   -- Initial contents of C port
      INIT_D => X"0000000000000000")   -- Initial contents of D port
   port map (
      DOA => R(i),    -- Read port A 1-bit output
      DOB => S(i),    -- Read port B 1-bit output
      DOC => T(i),    -- Read port C 1-bit output
      DOD => Dout(i), -- Read/Write port D 1-bit output
      ADDRA => rrloc, -- Read port A 6-bit address input
      ADDRB => sloc,  -- Read port B 6-bit address input
      ADDRC => tloc,  -- Read port C 6-bit address input
      ADDRD => dloc,  -- Read/Write port D 6-bit address input
      DIA => Din(i),  -- RAM 1-bit data write input addressed by ADDRD,
					  -- read addressed by ADDRA
      DIB => Din(i),  -- RAM 1-bit data write input addressed by ADDRD,
                      -- read addressed by ADDRB
      DIC => Din(i),  -- RAM 1-bit data write input addressed by ADDRD,
                      -- read addressed by ADDRC
      DID => Din(i),  -- RAM 1-bit data write input addressed by ADDRD,
                      -- read addressed by ADDRD
      WCLK => clk,    -- Write clock input
      WE => LUTwe     -- Write enable input
   );
   -- End of RAM64M_inst instantiation
end generate;

--      main memory (both program and data) implemented in single port block RAM
--			Inferred single port block RAM (LUT RAM used if address is 6-bits or less)
blkRAM: process (clk)
begin
if (clk'event and clk = '1') then
    blkrdata <= mem512x24(conv_integer(rwadr));
    if blkwe = '1' then
        mem512x24(conv_integer(rwadr)) <= blkwdata;
    end if;
end if;
end process;
rwadr	<= not pcN(mem_adr_size-1 downto 0);
inst	<= blkrdata;
blkwdata<= Dout;

pcp1    <= PC+1;
pcpN    <= PC+sNN;
--      instruction decode and implementation
decode: process(inst,pc,S,sNN,R,RR,SS,CCR,Dloc,opcode,aluout,pfx_st,pfx_reg,state,blkrdata,br_rslt,in0,sloc,pcp1,pcpN,adder,cry)
begin
--		default signal values
pcN<=pcp1; pcwe<='1'; outwe<='0'; ALUout<=adder; LUTwe<='0'; CCRwe<='0'; cry_ovfl_we<='0';
RR<= '0'&R; pfx_stn<='0'; pfx_stne<='0'; cry<='0'; 
Din<= ALUout(data_size-1 downto 0); 
blkwe<='0'; stateN<=NORMst; SS<='0'&S; 
--      prefix treatment
if opcode(4)='1' then SS <= '0' & pfx_reg & sloc; end if; SSS<=SS;
if opcode(4)='1' and pfx_st='1' then pfx_stne<='1'; end if;  -- use prefix if sN instruction
--      instruction processing states
case state is
when LDst   => ALUout<='0'&blkrdata; LUTwe<='1';                                              -- 2nd cycle of Mem read

when STst   => null;                                                                          -- 2nd cycle of Mem write

when NORMst =>                                                                                -- normal instruction cycle
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
        when op_LD    | op_LDN      =>                  pcN<=adder(23 downto 0);               stateN<=LDst; pcwe<='0';
        when op_ST    | op_STN      =>                  pcN<=adder(23 downto 0);   blkwe<='1'; stateN<=STst; pcwe<='0';
        when op_CALL  | op_CALLN    => Din<=pcp1;       pcN<=adder(23 downto 0); LUTwe<='1';
        when op_JMPCC | op_JMPCCN   => if br_rslt='1' then pcN<=adder(23 downto 0);   end if;
        when op_LDI                 => ALUout<='0'&sNN;                          LUTwe<='1';
        when op_CALLR               => Din<=pcp1; pcN<=pcpN;                     LUTwe<='1';
        when op_BRCC                => if br_rslt='1' then pcN<=pcpN;                 end if;
        when op_PFX                 => pfx_stn<='1';  pfx_stne<='1';
        when op_IN                  => Din<=in0;                                 LUTwe<='1';	-- for now only one input port
        when op_OUT                 =>                                           outwe<='1';	-- for now only one output port
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
adder<= RR + SSS + cry;

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
    if pcwe = '1'           then pc<=pcN(23 downto 0); end if; 
    if CCRwe = '1'          then CCR(23 downto 0)<=CCRN(23 downto 0); end if;
    if cry_ovfl_we = '1'    then CCR(26 downto 24) <=CCRN(26 downto 24); end if;    -- for overflow and carry bits
    if outwe = '1'          then out0<=Dout; end if;		                        -- for now only one output port
    if pfx_stne = '1'       then pfx_st<=pfx_stn; end if;                           -- update prefix state 
    if pfx_stne = '1'       then
        if pfx_stn='0' then pfx_reg<=(others => '0'); else pfx_reg<=inst(17 downto 0); end if; -- update prefix register
        end if;
end if;
end process;

end RTL;

