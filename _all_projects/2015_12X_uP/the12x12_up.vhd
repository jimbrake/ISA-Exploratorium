----------------------------------------------------------------------------------
-- Company:         Brakefield Research
-- Engineer:        James Brakefield
-- 
-- Create Date:    19:35:47 09/29/2015 
-- Design Name: 
-- Module Name:    the12x12_up - Behavioral 
-- Project Name:    The12X_12uP
-- Target Devices:  Kintex7 speed grade 3
-- Tool versions:   ISE 14.7
-- Description:     Stack/accumulator hybrid processor with 12-bit registers and addressing
--  data stack pointer (sp) descending with ascending offsets
--  frame pointer (fp) with descending offsets and within data stack
--  return stack pointer (rp) ascending
--  2nd operand pointer (op) is sp+NNN or fp-NNN or rp or immediate
--  result pointer (dp) is sp or sp-1 or op
--  instruction format: XXXXXRPEMNNN or XXXXXXsNNNNN or XXXXXRPsNNNN
--      X: op-code, R: return flag, P: stack mode, E: replace mode, s: 2's complement sign, N: offset or value
--  merged return & data stacks, 64 locations, 12-bit wide 
-- Dependencies: 
--
-- Revision:        0.01.01 "hello world" demo: enough instructions to output 8-bits from a 36-bit binary counter
-- Revision:        0.01.02 "hello world" demo: test for push button pressed
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
USE work.constants.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity the12x_12up is Port (    -- 12-bit soft core processor using 64X12 LUTRAM for stacks & 4KX12 block RAM for program
    CLOCK_Y3 : in STD_LOGIC;                                 -- master clock, fully synchronous design
--    reset    : in   STD_LOGIC;                             -- for reset reload FPGA
----  test bench signals
--    pc_tb       : out STD_LOGIC_VECTOR (data_size-1 downto 0);  -- current instruction address
--    Q_tb        : out std_logic_vector (data_size-1 downto 0);  -- current instruction
--    RSLT_tb     : out std_logic_vector (data_size-1 downto 0);  -- ALU result
--    sp_tb       : out STD_LOGIC_VECTOR (LUTRAM_adr_size-1 downto 0);    -- stack pointer
--    op_tb       : out STD_LOGIC_VECTOR (LUTRAM_adr_size-1 downto 0);    -- 2nd operand pointer
--    dp_tb       : out STD_LOGIC_VECTOR (LUTRAM_adr_size-1 downto 0);    -- result pointer
--    CCRZ_tb     : out STD_LOGIC;    -- new Zero status bit
--    CCRwe_tb    : out STD_LOGIC;    -- status bit update enable                       
--    LUTwe_tb    : out STD_LOGIC;    -- LUT RAM write enable
--    outwe_tb    : out STD_LOGIC;    -- output port write enable
--  # User input button & switches  # high = pushed or on
    USER_RESET  : in STD_LOGIC;     --LOC = V4 | IOSTANDARD = LVCMOS33 | PULLDOWN | TIG;# "USER_RESET"
    GPIO_DIP4   : in STD_LOGIC;     --LOC = A4 | IOSTANDARD = LVCMOS33 | PULLDOWN;      # "GPIO_DIP4"
    GPIO_DIP3   : in STD_LOGIC;     --LOC = B4 | IOSTANDARD = LVCMOS33 | PULLDOWN;      # "GPIO_DIP3"
    GPIO_DIP2   : in STD_LOGIC;     --LOC = A3 | IOSTANDARD = LVCMOS33 | PULLDOWN;      # "GPIO_DIP2"
    GPIO_DIP1   : in STD_LOGIC;     --LOC = B3 | IOSTANDARD = LVCMOS33 | PULLDOWN;      # "GPIO_DIP1"
--  # User LEDs                     # high = lit, no series resistor!			
    GPIO_LED1  : out  STD_LOGIC;    --LOC = P4 | IOSTANDARD = LVCMOS18;                 # "GPIO_LED1"
    GPIO_LED2  : out  STD_LOGIC;    --LOC = L6 | IOSTANDARD = LVCMOS18;                 # "GPIO_LED2"
    GPIO_LED3  : out  STD_LOGIC;    --LOC = F5 | IOSTANDARD = LVCMOS18;                 # "GPIO_LED3"
    GPIO_LED4  : out  STD_LOGIC);   --LOC = C2 | IOSTANDARD = LVCMOS18;                 # "GPIO_LED4"
end the12x_12up;

architecture RTL of the12x_12up is
type blkRAM_type is array(mem_size-1 downto 0) of std_logic_vector(data_size-1 downto 0);       -- block RAM array type
type state_type is (NORMst, TRAPst, MRDst, MWTst); -- normal inst, 2nd phase trap inst or branch/call inst, 2nd phase mem read, 2nd phase mem write

signal state, stateN : state_type:=NORMst;  --  state variable for multiple clock instructions

--  block RAM signals
signal M        : blkRAM_type:=(                                    -- block RAM
    op_LDI  OR op_P,           -- loc 0x0  push zero
    op_LDI  OR op_P,           -- loc 0x1  push zero
    op_LDI  OR op_P,           -- loc 0x2  push zero
    op_INC  OR "000000000010", -- loc 0x3  inc first zero           sp+2
    op_BNZ  OR "000000111111", -- loc 0x4  loop to 0x3 if non-zero  *-1
    op_CALL OR "000000000111", -- loc 0x5  call to inst at 0xC      *+7
    op_INC  OR "000000000001", -- loc 0x6  inc second zero          sp+1
    op_BNZ  OR "000000111100", -- loc 0x7  loop to 0x3 if non-zero  *-1
    op_INC  OR "000000000000", -- loc 0x8  inc third zero           sp
    op_OUT,                    -- loc 0x9  output third zero
    op_BNZ  OR "000000111001", -- loc 0xA  loop to 0x3 if non-zero  *-7
    op_BZ   OR "000000111000", -- loc 0xB  branch to 0x3            *-8
    op_IN   OR op_P,           -- loc 0xC  input switches & user PB and push onto stack 
    op_ANDI OR "000000010000", -- loc 0xD  test for PB pushed
    op_OUT  OR op_P,           -- loc 0xE  output and pop stack (e.g. pop stack with no CCR change)
    op_BZ   OR "000000111101", -- loc 0xF  loop to 0xD if zero      *-2
    op_OUT  OR op_R,           -- loc 0x10 output and return
    OTHERS => op_NOP);         -- other locations: NOP 
signal Me       : std_logic:='1';                                   -- block RAM enable
signal adr      : std_logic_vector(mem_adr_size-1 downto 0);        -- block RAM instruction address port
signal q	    : std_logic_vector(data_size-1 downto 0);           -- block RAM instruction read data port
signal Madr     : std_logic_vector(mem_adr_size-1 downto 0);        -- block RAM data address port
signal Mwd	    : std_logic_vector(data_size-1 downto 0);           -- block RAM write data port
signal Mwe      : std_logic;                                        -- block RAM write enable
signal Mrd	    : std_logic_vector(data_size-1 downto 0);           -- block RAM read data port
--  LUT RAM signals
signal lutwe    : std_logic;                                        -- quad port LUT RAM write enable
signal sp   : std_logic_vector(LUTRAM_adr_size-1 downto 0):=(OTHERS => '1');    -- starts at 0X3F  "data stack pointer"
signal fp   : std_logic_vector(LUTRAM_adr_size-1 downto 0):=(OTHERS => '0');    -- starts at 0X00  "frame or locals pointer"
signal rp   : std_logic_vector(LUTRAM_adr_size-1 downto 0):=(OTHERS => '1');    -- starts at 0X00  "return pointer"
signal pc   : std_logic_vector(data_size-1 downto 0):=(OTHERS => '0');          -- starts at 0X000 "program counter"
signal spN, rpN, fpN, op, dp, N4: std_logic_vector(LUTRAM_adr_size-1 downto 0); -- next/new data stack and return stack pointers, operand ptr, result/destination ptr
signal TOS, OPND, RSLT, RTNA    : std_logic_vector(data_size-1 downto 0);       -- LUT RAM data ports: top of stack, 2nd operand, result, return address
signal DOD, OPNDtmp             : std_logic_vector(data_size-1 downto 0);       -- unused quad port R/W port output
--  registers & "wires"
signal pcN                      : std_logic_vector(data_size-1 downto 0);       -- next/new program counter    
signal pcNe                     : std_logic:='0';                               -- pc update enable
signal inst                     : std_logic_vector(data_size-1 downto 0);       -- current instruction (block RAM data output)
signal outwe                    : std_logic:='0';                               -- enable for output port
signal N7,N6,N5                 : std_logic_vector(data_size-1 downto 0);       -- displacements embedded in instruction, varies with instruction
signal EXTNDr,EXTNDrN           : std_logic_vector(7-1 downto 0);               -- for EXTND instruction
signal EXTNDre                  : std_logic;
signal in0                      : std_logic_vector(data_size-1 downto 0);
signal out0                     : std_logic_vector(data_size-1 downto 0):=(OTHERS => '0');
signal CCR                      : std_logic_vector(data_size+1 downto 0):=(OTHERS => '0');  -- control & status register
signal CCRN                     : std_logic_vector(data_size+1 downto 0);                   -- next/new control & status register
signal CCRwe                    : std_logic;        -- enable for CCR update
signal CCR_eval,XCCR_eval       : boolean;          -- conditional branch to be taken
signal clk                      : std_logic;        -- VHDL clock name
signal mulin1				    : std_logic_vector(17-1 downto 0);
signal mulin2				    : std_logic_vector(17-1 downto 0);
signal mulout		            : std_logic_vector(mulin1'length+mulin2'length-1 downto 0);
signal bits_PnE                 : std_logic_vector(1 downto 0);

function CCR_gen(rslt: in std_logic_vector) return std_logic_vector is                      -- generate CCR bits
variable CCRn : std_logic_vector(data_size+1 downto 0):=(OTHERS => '0');
begin
CCRn(data_size-1 downto 0):= RSLT;  -- to minimize logic levels, conditional instructions do decode of result bits, carrry & overflow
--  CCRn(data_size):=?; CCRn(data_size+1):=?;       --  carry & overflow not yet implemented
return CCRn;
end function;

function CCR_unpack(packed: in std_logic_vector) return std_logic_vector is                 -- unpack CCR bits from stack value output
variable CCRn : std_logic_vector(data_size+1 downto 0):=(OTHERS => '0');
begin
CCRn(0) := packed(CCRbit_L);                                                                -- set LSB
CCRn(data_size-1) := packed(CCRbit_N);                                                      -- set MSB
if packed(CCRbit_low0s)='1' then CCRn(CCRlowend downto CCRlowst) := "00000";                -- fill low all zeros/all ones field
    elsif packed(CCRbit_low1s)='1' then CCRn(CCRlowend downto CCRlowst) := "11111";
    else CCRn(CCRlowend downto CCRlowst) := "00011"; end if;                                -- fill with mixed field if neither

if packed(CCRbit_hgh0s)='1' then CCRn(CCRhighend downto CCRhighst) := "00000";              -- fill high all zeros/all ones field 
    elsif packed(CCRbit_hgh1s)='1' then CCRn(CCRhighend downto CCRhighst) := "11111";
    else CCRn(CCRhighend downto CCRhighst) := "00011"; end if;                              -- fill with mixed field if neither
CCRn(data_size) := packed(CCRbit_V);                                                        -- set overflow bit
CCRn(data_size+1) := packed(CCRbit_C);                                                      -- set carry bit
return CCRn;
end function;

function CCR_pack(CCR: in std_logic_vector) return std_logic_vector is                     -- pack CCR bits for CCR input to stack
variable CCRpkd : std_logic_vector(data_size-1 downto 0):=(OTHERS => '0');
begin
CCRpkd(CCRbit_L) := CCR(0);                                                                -- set LSB
CCRpkd(CCRbit_N) := CCR(data_size-1);                                                      -- set MSB
if CCR(CCRlowend  downto CCRlowst) ="00000" then CCRpkd(CCRbit_low0s):='1'; else CCRpkd(CCRbit_low0s):='0'; end if;
if CCR(CCRlowend  downto CCRlowst) ="11111" then CCRpkd(CCRbit_low1s):='1'; else CCRpkd(CCRbit_low1s):='0'; end if;
if CCR(CCRhighend downto CCRhighst)="00000" then CCRpkd(CCRbit_hgh0s):='1'; else CCRpkd(CCRbit_hgh0s):='0'; end if;
if CCR(CCRhighend downto CCRhighst)="11111" then CCRpkd(CCRbit_hgh1s):='1'; else CCRpkd(CCRbit_hgh1s):='0'; end if;
CCRpkd(CCRbit_V) := CCR(data_size);                                                        -- set overflow bit
CCRpkd(CCRbit_C) := CCR(data_size+1);                                                      -- set carry bit
return CCRpkd;
end function;

function CCR_evalf(CCR: in std_logic_vector; inst: in std_logic_vector) return boolean is     -- CCR tests
variable rslt : boolean := false;
begin
case inst(3 downto 0) is                                                                                                -- tests for:
    when CCRZ  | CCRNZ => rslt := CCR(data_size-1 downto 0) = "000000000000" XOR inst(0)='1';                               -- 0
    when CCRCS | CCRCC => rslt := CCR(data_size+1) = '1'                     XOR inst(0)='1';                               -- carry set 
    when CCRMI | CCRPL => rslt := CCR(data_size-1) = '1'                     XOR inst(0)='1';                               -- MSB set
    when CCROD | CCREV => rslt := CCR(0) = '1'                               XOR inst(0)='1';                               -- LSB set
    when CCRVS | CCRVC => rslt := CCR(data_size) = '1'                       XOR inst(0)='1';                               -- overflow set
    when CCRLE | CCRGT => rslt := (CCR(data_size-1 downto 0)="000000000000" OR                                              -- zero or (negative xor overflow)
                                                      (CCR(data_size-1)='1' XOR CCR(data_size)='1'))    XOR inst(0)='1';
    when CCRGE | CCRLT => rslt := CCR(data_size-1) = '1' XOR CCR(data_size) = '1'                       XOR inst(0)='1';    -- negative xor overflow
    when CCRLS | CCRHI => rslt := (CCR(data_size+1) = '1' OR CCR(data_size-1 downto 0) = "000000000000")XOR inst(0)='1';    -- carry or zero
    when others => null;
    end case;
return rslt;
end function;

function XCCR_evalf(CCR: in std_logic_vector; inst: in std_logic_vector) return boolean is     -- extended CCR tests
variable rslt : boolean := false;
begin
case inst(3 downto 0) is                                                                                                        -- tests for:
    when CCRNEG1    | CCRNNEG1 => rslt :=  CCR(data_size-1 downto 0) = "111111111111" XOR inst(0)='1';                              -- -1
    when CCRONE     | CCRNONE  => rslt := (CCR(data_size-1 downto 1) = "00000000000"  AND CCR(0)='1') XOR inst(0)='1';              -- +1
    when CCRSMIN    | CCRNSMIN => rslt := (CCR(data_size-2 downto 1) = "0000000000"   AND CCR(data_size-1)='1') XOR inst(0)='1';    -- 0X800
    when CCRSMAX    | CCRNSMAX => rslt := (CCR(data_size-2 downto 1) = "1111111111"   AND CCR(data_size-1)='0') XOR inst(0)='1';    -- 0X7FF
    when CCRNEG2    | CCRNNEG2 => rslt := (CCR(data_size-1 downto 1) = "11111111111"  AND CCR(0)='0') XOR inst(0)='1';              -- -2
    when CCR0OR1    | CCRN0OR1 => rslt :=  CCR(data_size-1 downto 1) = "00000000000"  XOR inst(0)='1';                              -- 0 or +1
    when CCR0ORNEG1 | CCRN0ORNEG1 => rslt := (CCR(data_size-1 downto 0) = "000000000000" OR                                         -- 0 or -1
                                              CCR(data_size-1 downto 0) = "111111111111") XOR inst(0)='1'; 
    when CCR01ORNEG1| CCRN01ORNEG1=> rslt := (CCR(data_size-1 downto 1) = "000000000000" OR                                         -- 0 or +1 or -1
                                              CCR(data_size-1 downto 0) = "111111111111") XOR inst(0)='1'; 
    when others => null;
    end case;
return rslt;
end function;

begin
----  test bench assignments
--pc_tb       <=pc;
--Q_tb        <=Q;
--RSLT_tb     <=RSLT;
--sp_tb       <=spN;
--op_tb       <=op;
--dp_tb       <=dp;
--CCRZ_tb     <=CCRZN;
--CCRwe_tb    <=CCRwe;
--LUTwe_tb    <=LUTwe;
--outwe_tb    <=outwe;
--  misc signal assignments
clk<=CLOCK_Y3;
GPIO_LED1<=out0(0);
GPIO_LED2<=out0(1);
GPIO_LED3<=out0(2);
GPIO_LED4<=out0(3);
in0(11 downto 5)<= (OTHERS => '0');
in0(4)<= USER_RESET;
in0(3)<= GPIO_DIP4;
in0(2)<= GPIO_DIP3;
in0(1)<= GPIO_DIP2;
in0(0)<= GPIO_DIP1;
--  program memory relay assignments
adr<=pc(mem_adr_size-1 downto 0);
inst<=Q;
--  displacement generation
N7<="00000"&inst(6 downto 0);
N6<=inst(5)&inst(5)&inst(5)&inst(5)&inst(5)&inst(5)&inst(5 downto 0);           -- 2's complement 6-bit displacement for branches
N5<=inst(4)&inst(4)&inst(4)&inst(4)&inst(4)&inst(4)&inst(4)&inst(4 downto 0);   -- 2's complement 5-bit displacement for immediates
N4<="00"&inst(3 downto 0);                                                      -- unsigned 4-bit displacement for 2nd operand address
--  multiply
mulin1 <= "00000"&TOS;
mulin2 <= "00000"&OPND;
mulout <= std_logic_vector( signed(mulin1) * signed(mulin2) );
--  CCR calculations
CCR_eval  <= CCR_evalf(CCR, inst);      -- always generate branch to be taken 
XCCR_eval <= XCCR_evalf(CCR, inst);     -- always generate branch to be taken
bits_PnE  <= inst(bit_P) & inst(bit_E); -- for case statement in DIV & FDIV

--      64X12 quad port LUT RAM for data and return stacks
LUTRAM_generate: for i in 0 to data_size-1 generate
begin
--  data and return stacks implemented in a single quad port LUT RAM (uses 48 LUTs)
  -- RAM64M: 64-deep by 4-wide Multi Port LUT RAM (Mapped to four SliceM LUT6s): Kintex-7 & Spartan-6
  -- Xilinx HDL Language Template, version 14.7
   RAM64M_inst : RAM64M
   generic map (
      INIT_A => X"0000000000000000",   -- Initial contents of A port
      INIT_B => X"0000000000000000",   -- Initial contents of B port
      INIT_C => X"0000000000000000",   -- Initial contents of C port
      INIT_D => X"0000000000000000")   -- Initial contents of D port
   port map (
      DOA   => TOS(i),  -- Read port A 1-bit output
      DOB   => OPND(i), -- Read port B 1-bit output
      DOC   => RTNA(i), -- Read port C 1-bit output
      DOD   => DOD(i),  -- Read/Write port D 1-bit output (unused)
      ADDRA => sp,      -- Read port A 6-bit address input (stack pointer)
      ADDRB => op,      -- Read port B 6-bit address input (2nd operand pointer)
      ADDRC => rp,      -- Read port C 6-bit address input (return stack pointer)
      ADDRD => dp,      -- Read/Write port D 6-bit address input (result pointer)
      DIA   => RSLT(i), -- RAM 1-bit data write input addressed by ADDRD,
      DIB   => RSLT(i), -- RAM 1-bit data write input addressed by ADDRD,
      DIC   => RSLT(i), -- RAM 1-bit data write input addressed by ADDRD,
      DID   => RSLT(i), -- RAM 1-bit data write input addressed by ADDRD,
      WCLK  => clk,     -- Write clock input
      WE    => LUTwe    -- Write enable input
   );
   -- End of RAM64M_inst instantiation
end generate;

--      inferred dual port block RAM
process (clk)
begin
   if (clk'event and clk = '1') then
      if (Me = '1') then
         if (Mwe = '1') then
            M(conv_integer(Madr)) <= Mwd;
         end if;
         Mrd <= M(conv_integer(Madr));
         Q <= M(conv_integer(adr));
      end if;
   end if;
end process;

--      instruction decode
decode: process(state,inst,pc,sp,spN,rp,fp,rpN,op,CCR,N4,N7,N6,N5,TOS,OPND,DOD,RSLT,
                IN0,RTNA,Mrd,OPNDtmp,mulout,bits_PnE,CCR_eval,XCCR_eval)
begin
CCRn<=ccr_gen(RSLT);              -- always generate CCRN, use CCRwe to control update 
Madr<=OPND(mem_adr_size-1 downto 0); Mwd<=TOS; OPNDtmp<=(others => '0');
stateN<=NORMst; EXTNDre<='0'; EXTNDrN<=N7(7-1 downto 0);
pcNe<='1'; pcN<=pc+1; Mwe<='0';                      -- process defaults 
dp<=sp; spN<=sp; rpN<=rp; fpN<=fp; outwe<='0';       -- process defaults
RSLT<=(others => '0'); LUTwe<='0'; CCRwe<='0';       -- process defaults
     
--  MNNN stack offset arithmetic,  sp is descending, rp is ascending
--op<=sp+N4;                    -- simple offset arithmetic if no frame pointer
case inst(3 downto 0) is        -- RTL that works a little better
    when "0000" => op<=sp;
    when "0001" => op<=sp+"000001";
    when "0010" => op<=sp+"000010";
    when "0011" => op<=sp+"000011";
    when "0100" => op<=sp+"000100";
    when "0101" => op<=sp+"000101";
    when "0110" => op<=sp+"000110";
    when "0111" => op<=sp+"000111";     -- immediate at PC+1 not implemented, so map to sp+7
    when "1000" => op<=fp+"000000";
    when "1001" => op<=fp+"111111";
    when "1010" => op<=fp+"111110";
    when "1011" => op<=fp+"111101";
    when "1100" => op<=fp+"111100";
    when "1101" => op<=fp+"111011";
    when "1110" => op<=fp+"111010";
    when "1111" => op<=rp;
    when others => null;
    end case;

--  instruction processing states
case state is
when TRAPst => pcN<=inst;                                                                                       -- 2nd cylce of trap inst

when MRDst   => RSLT<=Mrd; LUTwe<='1';                                                                          -- 2nd cylce of Mem read
        if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

when MWTst   =>                                                                                                 -- 2nd cylce of Mem write
        if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

when NORMst =>                                                                                                  -- normal instruction cycle
--      instruction dispatch & arithmetic
    case inst(11 downto 7) is

        when op_TRAP(11 downto 7) => pcN<=N7; stateN<=TRAPst;       -- two port block RAM not required!                     --  TRAP

        when op_EXTND(11 downto 7) => EXTNDre<='1';                                                                         --  EXTND

        when op_CALL(11 downto 7) => pcN<=pc+N6;                                                                    -- both CALL and BR
            if inst(bit_R) = '0' then LUTwe<='1'; rpN<=rp+1; dp<= rpN; RSLT<=PC+1; end if;                                  -- CALL

        when op_BZ(11 downto 7) => if inst(bit_R)='1' XOR CCR(data_size-1 downto 0)="000000000000" then pcN<=pc+N6; end if; -- both BZ and BNZ

        when op_LD(11 downto 7) => pcN<=pc; Madr<=OPND(mem_adr_size-1 downto 0);                                    --  both LD and ST
            case inst(bit_E) is
                when op_LD(bit_E) => stateN<=MRDst;                                                                         -- LD
                        if inst(bit_P)='1' then spN<=sp-1; end if;
                when op_ST(bit_E) => stateN<=MWTst; Mwd<=TOS; Mwe<='1';                                                     -- ST 
                        if inst(bit_P)='1' then spN<=sp+1; end if;
                when others       => null;
                end case;

        when op_LDoff(11 downto 7) => pcN<=pc; OPNDtmp<=OPND+TOS; Madr<=OPNDtmp(mem_adr_size-1 downto 0);           --  both LDoff and SToff
            case inst(bit_E) is
                when op_LD(bit_E) => stateN<=MRDst;                                                                         -- LDoff
                        if inst(bit_P)='1' then spN<=sp-1; end if;
                when op_ST(bit_E) => stateN<=MWTst; dp<=sp+1; Mwd<=DOD; Mwe<='1';                                           -- SToff 
                        if inst(bit_P)='1' then spN<=sp+1; end if;
                when others       => null;
                end case;

        when op_LDpp(11 downto 7) => pcN<=pc; Madr<=OPND(mem_adr_size-1 downto 0);                                  --  both LDpp and STpp
            RSLT<=OPND+1; dp<=rpN; LUTwe<='1';
            case inst(bit_E) is
                when op_LD(bit_E) => stateN<=MRDst;                                                                         -- LDpp
                        if inst(bit_P)='1' then spN<=sp-1; end if;
                when op_ST(bit_E) => stateN<=MWTst; Mwd<=TOS; Mwe<='1';                                                     -- STpp 
                        if inst(bit_P)='1' then spN<=sp+1; end if;
                when others       => null;
                end case;

        when op_LDnn(11 downto 7) => pcN<=pc; OPNDtmp<=OPND-1; Madr<=OPNDtmp(mem_adr_size-1 downto 0);              --  both LDnn and STnn
            RSLT<=OPND-1; dp<=rpN; LUTwe<='1';
            case inst(bit_E) is
                when op_LD(bit_E) => stateN<=MRDst;                                                                         -- LDnn
                        if inst(bit_P)='1' then spN<=sp-1; end if;
                when op_ST(bit_E) => stateN<=MWTst; Mwd<=TOS; Mwe<='1';                                                     -- STnn 
                        if inst(bit_P)='1' then spN<=sp+1; end if;
                when others       => null;
                end case;

        when op_ANDI(11 downto 7)=> LUTwe<='1'; dp<=op;  RSLT<=N5 AND OPND; if inst(bit_P)='1' then spN<=sp-1; end if;      -- ANDI
            CCRwe<='1'; 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_ORI(11 downto 7) => LUTwe<='1'; dp<=op;  RSLT<=N5 OR OPND;  if inst(bit_P)='1' then spN<=sp-1; end if;      -- ORI
            CCRwe<='1'; 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_XORI(11 downto 7)=> LUTwe<='1'; dp<=op;  RSLT<=N5 XOR OPND; if inst(bit_P)='1' then spN<=sp-1; end if;      -- XORI
            CCRwe<='1'; 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_LDI(11 downto 7) => LUTwe<='1'; dp<=op;  RSLT<=N5;          if inst(bit_P)='1' then spN<=sp-1; end if;      -- LDI
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_ADDI(11 downto 7)=> LUTwe<='1'; dp<=op;  RSLT<=N5 + OPND;   if inst(bit_P)='1' then spN<=sp-1; end if;      -- ADDI
            CCRwe<='1'; 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_CMPI(11 downto 7)=>                      RSLT<=OPND - N5;   if inst(bit_P)='1' then spN<=sp+1; end if;      -- CMPI
            CCRwe<='1'; 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

    --  SHIFT
        
        when op_PICK(11 downto 7) =>                                                                               -- both PICK and POCK 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return
            case inst(bit_E) is
                when op_PICK(bit_E) => if inst(bit_P)='1' then spN<=sp-1; end if; LUTwe<='1'; RSLT<=OPND; dp<= spN;         -- PICK
                when op_POCK(bit_E) => if inst(bit_P)='1' then spN<=sp+1; end if; LUTwe<='1'; RSLT<=TOS; dp<= op;           -- POCK
                when others         => null;
                end case;

        when op_IN(11 downto 7) =>                                                                                  -- both IN and OUT 
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return
            case inst(bit_E) is
                when op_IN(bit_E)  => if inst(bit_P)='1' then spN<=sp-1; end if; LUTwe<='1'; dp<= spN;                      -- IN
                                      if inst(3 downto 0)="1111" then RSLT<=CCR_pack(CCR); else RSLT<=in0; end if;   --CCR is port 15
                when op_OUT(bit_E) => if inst(bit_P)='1' then spN<=sp+1; end if;                                            -- OUT
                                      if inst(3 downto 0)="1111" then CCRN<=CCR_unpack(TOS); else outwe<='1'; end if;--CCR is port 15 
                when others        => null;
                end case;

        when op_POPFP(11 downto 7) =>                                                                               -- POPFP, PUSHFP, DROPn and INITstk
            case inst(5 downto 4) is
                when op_POPFP(5 downto 4)  =>                                                                               -- POPFP ugh: two reads of rtn stack
                    if inst(bit_R) = '0' then fpN<=RTNA(5 downto 0); rpN<=rp-1; spN<=fp-N4;                                 -- POPFP without return
                        else fpN<=RTNA(5 downto 0); op<= rp-1; rpN<=rp-2; pcN<=OPND; end if;                                -- POPFP with return
                when op_PUSHFP(5 downto 4) => LUTwe<='1'; RSLT<="000000" & fp; fpN<=sp+N4; rpN<=rp+1; dp<= rpN;             -- PUSHFP, bit_R=1 not allowed
                when op_DROPn(5 downto 4)  => spN<=sp+N4;                                                                   -- DROPn
                    if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return
    -- INITstk
                when others                => null;                                                                         -- INITstk not implemented
                end case;

        when op_INC(11 downto 7) =>                                                                                 -- INC, DEC, CLR and SET
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return
            case inst(5 downto 4) is
                when op_INC(5 downto 4) => LUTwe<='1'; dp<=op;  RSLT<=OPND+1; CCRwe<='1';                                   -- INC
                when op_DEC(5 downto 4) => LUTwe<='1'; dp<=op;  RSLT<=OPND-1; CCRwe<='1';                                   -- DEC
                when op_CLR(5 downto 4) => LUTwe<='1'; dp<=op;  RSLT<=(OTHERS => '0');                                      -- CLR
                when op_SET(5 downto 4) => LUTwe<='1'; dp<=op;  RSLT<=(OTHERS => '1');                                      -- SET
                when others             => null;
                end case;

        when op_ADD(11 downto 7)=> LUTwe<='1'; CCRwe<='1'; RSLT<=TOS + OPND;                                                -- ADD
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_SUB(11 downto 7)=> LUTwe<='1'; CCRwe<='1';                                                                  -- SUB
            case inst(bit_E) is when '0' => RSLT<=TOS - OPND; when others => RSLT<=OPND - TOS; end case;    -- operands reverse when bit_E set
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_MUL(11 downto 7)=> LUTwe<='1'; CCRwe<='1';RSLT <= mulout(data_size-1 downto 0);                             -- MUL
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return
            
        when op_DIV(11 downto 7)=>   -- divide not implemented, will NOP                                            --  DIV and conditionals
            if inst(bit_R) = '1' then 
                case bits_PnE is
                when "00" => if CCR_eval  then pcN<=RTNA; else rpN<=rp-1; end if;                                       -- conditional looping
                when "01" => if CCR_eval  then RSLT<="000000000001"; else RSLT<="000000000000"; end if; -- conditional generate 0 or 1 and return
                                    rpN<=rp-1; pcN<=RTNA; dp<=sp-1; spN<=sp-1;                         
                when "10" => if CCR_eval  then RSLT<="000000000001"; else RSLT<="000000000000"; end if; -- conditional generate 0 or 1
                when "11" => if XCCR_eval then RSLT<="000000000001"; else RSLT<="000000000000"; end if; -- extended conditional generate 0 or 1
                when others => null;
                end case;
            end if;
        when op_AND(11 downto 7)=> LUTwe<='1'; CCRwe<='1'; RSLT<=TOS and OPND;                                              -- AND
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_OR(11 downto 7) => LUTwe<='1'; CCRwe<='1'; RSLT<=TOS or OPND;                                               -- OR
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_XOR(11 downto 7)=> LUTwe<='1'; CCRwe<='1'; RSLT<=TOS xor OPND;                                              -- XOR
            case inst(5 downto 4) is when "10" => spN<=sp-1; when "11" => spN<=sp+1; when others => null; end case; -- stack pointer adjustments
            if inst(bit_E) = '1' then dp<=op; else dp<=spN; end if;   -- set data store pointer
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

        when op_CMP(11 downto 7)=>             CCRwe<='1'; RSLT<=TOS - OPND;                                        -- CMP and FCMP
            if inst(bit_P) = '1' then spN<=sp-1; end if;              -- stack pointer adjustment
            if inst(bit_R) = '1' then rpN<=rp-1; pcN<=RTNA; end if;   -- if return bit set do the return

    --  FADD
    --  FSUB
    --  FMUL

        when op_FDIV(11 downto 7)=>   -- floating divide not implemented, will NOP                                  --  FDIV and conditionals
            if inst(bit_R) = '1' then 
                case bits_PnE is
                when "00" => if CCR_eval  then                 rpN<=rp-1; pcN<=RTNA; end if;                        -- conditional returns
                when "01" => if CCR_eval  then stateN<=TRAPst; LUTwe<='1'; rpN<=rp+1; dp<= rpN; RSLT<=PC+1; end if; -- conditional calls
                when "10" => if CCR_eval  then stateN<=TRAPst; end if;                                              -- conditional branches
                when "11" => if XCCR_eval then stateN<=TRAPst; end if;                                              -- extended conditional branches
                when others => null;
                end case;
            end if;
        when others => null;            -- NOP for now
    end case;       -- inst dispatch case

when others => null;
end case;       -- inst processing state case

end process;

--      state variable and register updates
update: process(clk)
begin
if (rising_edge(clk)) then
    if pcNe = '1' then pc<=pcN; end if;
    sp<=spN; rp<=rpN; fp<=fpN;      -- unconditional for now
    state<=stateN;
--  LUT RAM update: M(dp)<= RSLT enabled by LUTwe (do not uncomment, as a reminder)  
    if EXTNDre = '1' then EXTNDr<=EXTNDrN; end if;
    if CCRwe = '1' then CCR<=CCRN; end if;
    if outwe = '1' then out0<=TOS; end if;
end if;
end process;

end RTL;

