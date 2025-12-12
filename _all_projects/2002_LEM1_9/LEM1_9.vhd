----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		James C Brakefield
-- 
-- Create Date:    01/04/2017 
-- Design Name:		LEM1_9 
-- Module Name:    constants - Behavioral 
-- Project Name:		LEM1_9
-- Target Devices: xilinx Artix-7 chip, Digilent CMOD A7 board
-- Tool versions:	 Vivado 2016.2
-- Description:	Soft core processor with 9-bit instructions and 1-bit data
--		Single data bit at a time "accumulator instructions to/from data RAM.
--		Return address stack of 4+ addresses.
--		Supports 32-2048 word instruction ROM and 16-32 bits of data RAM.  IO mapped to data RAM locations.
--		Parameterization: return address stack depth (4-32), instruction address size (5-11), data RAM size (16-32).
--        Shorter/smaller values reduce LUT counts.
--      Program ROM is dual port so extended instructions do not require a second read cycle (all inst take one clock!)
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--  12/29/16 ISE 14.7 does not support small ARTIX-7s!  Will need to use Vivado for CMOD A7!
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
USE work.constants.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LEM1_9 is Port (    -- 1-bit soft core processor using 2Kx9 block RAM for program
    clk             : in STD_LOGIC;        -- 100MHz master clock, fully synchronous design
----      Test bench signals
--     PC_tb          : out  std_logic_vector(prog_adr_size-1 downto 0);
--     inst_tb        : out  std_logic_vector(inst_size-1 downto 0);
--     rstack_ptr_tb  : out  std_logic_vector(rtn_ptr_size-1 downto 0);
--     A_tb           : out  std_logic;
--     C_tb           : out  std_logic;
--     bitRAM_we_tb   : out  std_logic;
--     bitRAMw_DI_tb  : out  std_logic;
--     bitRAMw_DO_tb  : out  std_logic;
--      User push buttons
    GPIO_DIP1   : in   STD_LOGIC;
    GPIO_DIP2   : in   STD_LOGIC;
--      User LEDs			
    GPIO_LED1   : out  STD_LOGIC;   
    GPIO_LED2   : out  STD_LOGIC;      
    GPIO_LED3   : out  STD_LOGIC;  
    GPIO_LED4   : out  STD_LOGIC);  
end LEM1_9;

architecture RTL of LEM1_9 is

--	N suffix indicates new value, eg pc is current pc, pcN is new/next PC
signal accn, accwe : std_logic;            -- accumulator bit & next & enable
signal cryn, crywe : std_logic;            -- carry bit & next & enable
signal acc : std_logic:='0';            -- accumulator bit & next & enable
signal cry : std_logic:='0';            -- carry bit & next & enable
signal pcwe             : std_logic;            -- PC update enable    
signal pc               : std_logic_vector(prog_adr_size-1 downto 0):=(OTHERS => '1');    -- program counter
signal pcn              : std_logic_vector(prog_adr_size-1 downto 0);    -- next program counter

--  instruction field names
signal opcode	: std_logic_vector(2 downto 0);     -- main op-code
signal rbit	    : std_logic;                        -- "replace" bit
signal adr_ops  : std_logic_vector(2 downto 0);     -- branch/pointer op-codes
signal instadrs : std_logic_vector(10 downto 0);    -- extended inst program ROM address field
--signal ptradrs  : std_logic_vector(9 downto 0);     -- extended inst bit RAM address/displacement field

--      2R port block RAM for instructions
type instrom_type is array (prog_size-1 downto 0) of std_logic_vector (inst_size-1 downto 0);   -- instruction memory type              
signal instROM : instrom_type:= (                 -- instruction memory & initialization
op_SETC, op_SETC,   -- in case PC starts at 1
-- 0x02
op_CALL,"000000110",op_JMP,"000000100",                 -- loop forever to help locate faults
-- 0x06
op_CLRC,op_JCC,"000001010",op_RTN,                      --return/error if carry set
-- 0x0a
op_NOTC,op_JCS,"000001110",op_RTN,                      -- return/error if carry clear
-- 0x0e
op_SETC,op_JCS,"000010010",op_RTN,                      -- return/error if carry clear
-- 0x12
op_SETA,op_JAS,"000010110",op_RTN,                      --return/error if acc clear
-- 0x16
op_NOTA,op_JAC,"000011010",op_RTN,                      -- return/error if acc set
-- 0x1a
op_CLRA,op_JAC,"000011110",op_RTN,                      -- return/error if acc set
-- 0x1e
op_SWAP,op_JCC,"000100010",op_RTN,op_JAS,"000100101",op_RTN,                                             -- test SWAP
-- 0x25, C set and A clear
op_ST OR "000000110",op_INCM OR "000000110",op_LD OR "000000110",op_JAS,"000101011",op_RTN,              -- test load/store and increment
-- 0x2b
op_SETC, op_INCM OR "000000110",op_JCS,"000110000",op_RTN,op_LD OR "000000110",op_JAC,"000110100",op_RTN,-- test increment and carry propagation
-- 0x34
op_XOR OR "000000110",op_JAC,"000111000",op_RTN,        -- test XOR
-- 0x38
op_OR OR "000000110",op_JAC,"000111100",op_RTN,         -- test OR
-- 0x3c
op_STC OR "000000110",op_AND OR "000000110",op_JAC,"001000001",op_RTN,                                   -- test STC and AND
-- 0x41
op_CALL,"001000101",op_JMP,"001001011",op_CALL,"001001000",op_RTN,op_CALL,"001001010",op_RTN,            -- test nested calls
-- 0x4b, C set, A set, mem set
op_SETA,op_ST OR "000000110",op_ADC OR "000000110",op_JCS, "001010001",op_RTN,op_JAS,"001010100",op_RTN, -- test ADC
-- 0x54, clr C, A set, mem set
op_CLRA,op_RADC OR "000000110",op_JCS,"001011001",op_RTN,op_JAC,"001011100",op_RTN,                      -- test RADC
-- 0x5c
op_RTN,     -- end of tests

--      23-bit binary counter, top 4 bits to LEDs
--op_CALL,"000010000",op_CALL,"000010000",op_CALL,"000010000",op_CALL,"000010000",
--op_CALL,"000010000",op_CALL,"000010000",op_CALL,"000010000",op_JMP ,"000000000",
----  location "10000"
--op_SETC,
--op_INCM OR "000010110",op_INCM OR "000010101",op_INCM OR "000010100",op_INCM OR "000010011",
--op_INCM OR "000010010",op_INCM OR "000010001",op_INCM OR "000010000",op_INCM OR "000001111",
--op_INCM OR "000001110",op_INCM OR "000001101",op_INCM OR "000001100",op_INCM OR "000001011",
--op_INCM OR "000001010",op_INCM OR "000001001",op_INCM OR "000001000",op_INCM OR "000000111",
--op_INCM OR "000000110",op_INCM OR "000000101",op_INCM OR "000000100",op_INCM OR "000000011",
--op_INCM OR "000000010",op_INCM OR "000000001",op_INCM OR "000000000",
--op_JCC,    "000010000",
--op_RTN,
OTHERS => "000000000");
ATTRIBUTE ram_extract: string;
ATTRIBUTE ram_extract OF instROM: SIGNAL IS "yes";
ATTRIBUTE ram_style: string;
ATTRIBUTE ram_style OF instROM: SIGNAL IS "block";

signal inst, nxt_inst       : std_logic_vector(inst_size-1 downto 0);           -- instruction readouts
signal instadr, instadr_p1  : std_logic_vector(prog_adr_size-1 downto 0);       -- instruction addresses & PC
signal instROMwe            : std_logic;                                        -- used to invoke a dual port block ROM

--      1RW port LUT ram for return address stack
type rstack_ram_type is array (rtn_stack_size-1 downto 0) of std_logic_vector (prog_adr_size-1 downto 0);
signal rstack_ram : rstack_ram_type:= (OTHERS => "00000000");                   -- return stack LUT ram
signal rstack_ptrn, rstack_ptrx : std_logic_vector (rtn_ptr_size-1 downto 0);   -- pointer into return stack, new pointer & LUT address pointer
signal rstack_ptr : std_logic_vector (rtn_ptr_size-1 downto 0):=(OTHERS => '0');-- pointer into return stack, new pointer & LUT address pointer
signal rstack_do, rstack_di : std_logic_vector (prog_adr_size-1 downto 0);      -- return addresses in & out of stack
signal rstack_we : std_logic;                                                   -- enable write return adr to return stack

--      1RW port LUT RAM for bit ram file
type bitram_type is array (bitRAM_size-1 downto 0) of std_logic;                -- bit data ram type
signal bitRAM : bitram_type:= (OTHERS => '0');                                  -- bit data ram
signal bitRAMw_DI, bitRAMw_DO: std_logic;                                       -- bit data ram IOs
signal bitRAM_wadr: std_logic_vector(bitRAM_adr_size-1 downto 0);               -- bit data ram addresses
signal bitram_we : std_logic;

begin
----  Test bench signal assignments
--PC_tb           <=PC;
----PC_tb           <=instadr;
--inst_tb         <=inst;
--rstack_ptr_tb   <=rstack_ptr;
--A_tb            <=acc;
--c_tb            <=cry;
--bitRAM_we_tb    <=bitRAM_we;
--bitRAMw_DI_tb   <=bitRAMw_DI;
--bitRAMw_DO_tb   <=bitRAMw_DO;

bitRAM_wadr <= inst(bitRAM_adr_size-1 downto 0);    --  bit RAM uses absolute addresses

--      2R port block ROM for instructions
process (clk)
begin
if rising_edge(clk) then
    if (instROMwe = '1') then
       instROM(conv_integer(instadr)) <= "000000000";
    end if;
inst        <= instROM(conv_integer(instadr));
nxt_inst    <= instROM(conv_integer(instadr_p1));
end if;
end process;

--      1RW port LUT ram for return address stack
process (clk)
begin
if rising_edge(clk) then
if (rstack_we = '1') then
    rstack_ram(conv_integer(rstack_ptrx)) <= rstack_di;
end if;
end if;
end process;
rstack_do <= rstack_ram(conv_integer(rstack_ptrx));

--      1RW port LUT RAM for bit ram
process (clk)
begin
if rising_edge(clk) then
    if (bitRAM_we = '1') then
        bitRAM(conv_integer(bitRAM_wadr)) <= bitRAMw_DI;
        if bitRAM_wadr = "00000" then GPIO_LED1 <= bitRAMw_DI; end if;    -- map bit ram location to LED
        if bitRAM_wadr = "00001" then GPIO_LED2 <= bitRAMw_DI; end if;    -- map bit ram location to LED
        if bitRAM_wadr = "00010" then GPIO_LED3 <= bitRAMw_DI; end if;    -- map bit ram location to LED
        if bitRAM_wadr = "00011" then GPIO_LED4 <= bitRAMw_DI; end if;    -- map bit ram location to LED
    end if;
end if;
end process;
with bitRAM_wadr select
    bitRAMw_DO <= GPIO_DIP1 when "11110",         -- map push button to bit ram read location
                  GPIO_DIP2 when "11111",         -- map push button to bit ram read location
                  bitRAM(conv_integer(bitRAM_wadr)) when others;

--      Instruction ROM connect
instadr<= NOT pcn; instadr_p1<= NOT (pcn+1);

--      instruction decode and implementation
decode: process(inst,nxt_inst,instrom,pc,acc,cry, opcode,rbit,adr_ops,instadrs, rstack_ptr,rstack_do,bitramw_do)
begin
--		        parse the instruction (eg give names to instruction fields)
opcode	<= inst(8 downto 6);                        -- main op-code
rbit	<= inst(5);                                 -- "replace" bit
adr_ops <= inst(4 downto 2);                        -- branch/pointer op-codes
instadrs<= inst(1 downto 0) & nxt_inst(8 downto 0); -- extended inst program ROM address field

--		default signal values
pcn<=pc+1; pcwe<='1'; if (opcode = "111" AND rbit = '1') then pcn <= pc+2; end if;
accn<='0'; cryn<='0'; accwe<='0'; crywe<='0';
bitRAM_we<='0'; bitRAMw_DI <='0';
rstack_ptrx<=rstack_ptr; rstack_we<='0'; rstack_di <= pc+2; rstack_ptrn <= rstack_ptr - 1; -- only used by CALL & RTN, so defaults arranged for one of the two
instROMwe<='0';

if rbit = '0' then  --      write to accumulator instructions instruction implementation 
case opcode is
    when op_LD  (8 downto 6) => accn<=        bitRAMw_DO;         accwe<='1';
    when op_LDC (8 downto 6) => accn<=    NOT bitRAMw_DO;         accwe<='1';
    when op_AND (8 downto 6) => accn<=acc AND bitRAMw_DO;         accwe<='1';
    when op_OR  (8 downto 6) => accn<=acc OR  bitRAMw_DO;         accwe<='1';
    when op_XOR (8 downto 6) => accn<=acc XOR bitRAMw_DO;         accwe<='1';
    when op_ADC (8 downto 6) => accn<=acc XOR bitRAMw_DO XOR cry; accwe<='1';     cryn<=(acc AND cry)OR(acc AND bitRAMw_DO)OR(cry AND bitRAMw_DO); crywe<='1';
    when op_INCM(8 downto 6) => bitRAMw_DI<=bitRAMw_DO XOR cry;   bitram_we<='1'; cryn<=cry AND bitRAMw_DO; crywe<='1';
    when op_MACS(8 downto 6) => 
        case inst(4 downto 0) is        -- SCCAA: swap bit, carry & accum modifications: no change/complement/set to 0/set to 1; mods done before swap
            when "00000" => pcn <= rstack_do; rstack_ptrn <= rstack_ptr + 1; rstack_we <= '1'; -- op_RTN
            when "00001" => accn <= NOT acc; accwe <= '1';                                      -- op_NOTA
            when "00010" => accn <= '0'; accwe <= '1';                                          -- op_SAT0
            when "00011" => accn <= '1'; accwe <= '1';                                          -- op_SAT1
            when "00100" =>                                 cryn <= NOT cry; crywe <= '1';      --           op_NOTC
            when "00101" => accn <= NOT acc; accwe <= '1';  cryn <= NOT cry; crywe <= '1';      -- op_NOTA | op_NOTC
            when "00110" => accn <= '0'; accwe <= '1';      cryn <= NOT cry; crywe <= '1';      -- op_SAT0 | op_NOTC
            when "00111" => accn <= '1'; accwe <= '1';      cryn <= NOT cry; crywe <= '1';      -- op_SAT1 | op_NOTC
            when "01000" =>                                 cryn <= '0'; crywe <= '1';          --           op_SCT0
            when "01001" => accn <= NOT acc; accwe <= '1';  cryn <= '0'; crywe <= '1';          -- op_NOTA | op_SCT0
            when "01010" => accn <= '0'; accwe <= '1';      cryn <= '0'; crywe <= '1';          -- op_SAT0 | op_SCT0
            when "01011" => accn <= '1'; accwe <= '1';      cryn <= '0'; crywe <= '1';          -- op_SAT1 | op_SCT0
            when "01100" =>                                 cryn <= '1'; crywe <= '1';          --           op_SCT1
            when "01101" => accn <= NOT acc; accwe <= '1';  cryn <= '1'; crywe <= '1';          -- op_NOTA | op_SCT1
            when "01110" => accn <= '0'; accwe <= '1';      cryn <= '1'; crywe <= '1';          -- op_SAT0 | op_SCT1
            when "01111" => accn <= '1'; accwe <= '1';      cryn <= '1'; crywe <= '1';          -- op_SAT1 | op_SCT1
            --      swaps
            when "10000" => accn <= cry; accwe <= '1';      cryn <= acc; crywe <= '1';          --                      op_SWAP acc & cry after mods
            when "10001" => accn <= cry; accwe <= '1';      cryn <= NOT acc; crywe <= '1';
            when "10010" => accn <= cry; accwe <= '1';      cryn <= '0'; crywe <= '1';
            when "10011" => accn <= cry; accwe <= '1';      cryn <= '1'; crywe <= '1';
            when "10100" => accn <= NOT cry; accwe <= '1';  cryn <= acc; crywe <= '1';
            when "10101" => accn <= NOT cry; accwe <= '1';  cryn <= NOT acc; crywe <= '1';
            when "10110" => accn <= NOT cry; accwe <= '1';  cryn <= '0'; crywe <= '1';
            when "10111" => accn <= NOT cry; accwe <= '1';  cryn <= '1'; crywe <= '1';
            when "11000" => accn <= '0'; accwe <= '1';      cryn <= acc; crywe <= '1';
            when "11001" => accn <= '0'; accwe <= '1';      cryn <= NOT acc; crywe <= '1';
            when "11010" => null; -- redundant code
            when "11011" => null; -- redundant code
            when "11100" => accn <= '1'; accwe <= '1';      cryn <= acc; crywe <= '1';
            when "11101" => accn <= '1'; accwe <= '1';      cryn <= NOT acc; crywe <= '1';
            when "11110" => null; -- redundant code
            when "11111" => null; -- redundant code
            when others=> null;
        end case;
    when others => null;
end case;
else               --       write to bit RAM (replace) instructions instruction implementation
case opcode is
    when op_ST  (8 downto 6) => bitRAMw_DI<=               acc;         bitram_we<='1';
    when op_STC (8 downto 6) => bitRAMw_DI<=           NOT acc;         bitram_we<='1';
    when op_RAND(8 downto 6) => bitRAMw_DI<=bitRAMw_DO AND acc;         bitram_we<='1';
    when op_ROR (8 downto 6) => bitRAMw_DI<=bitRAMw_DO OR  acc;         bitram_we<='1';
    when op_RXOR(8 downto 6) => bitRAMw_DI<=bitRAMw_DO XOR acc;         bitram_we<='1';
    when op_RADC(8 downto 6) => bitRAMw_DI<=acc XOR bitRAMw_DO XOR cry; bitram_we<='1'; cryn<=(acc AND cry)OR(acc AND bitRAMw_DO)OR(cry AND bitRAMw_DO); crywe<='1';
    when op_DECM(8 downto 6) => bitRAMw_DI<=NOT bitRAMw_DO XOR cry;     bitram_we<='1'; cryn<=cry OR bitRAMw_DO; crywe<='1';
    when op_CALL(8 downto 6) => 
        case adr_ops is
            when op_CALL(4 downto 2) => pcn <= instadrs(prog_adr_size-1 downto 0); rstack_ptrx <= rstack_ptr - 1; rstack_we <= '1';
            when op_JMP (4 downto 2) => pcn <= instadrs(prog_adr_size-1 downto 0);
            when op_JAC (4 downto 2) => if acc = '0' then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JAS (4 downto 2) => if acc = '1' then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JCC (4 downto 2) => if cry = '0' then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JCS (4 downto 2) => if cry = '1' then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
--            when op_LDPT(4 downto 2) => bitptr_di <=             ptradrs(bitRAM_adr_size-1 downto 0); bitptr_we <= '1';
--            when op_ADPT(4 downto 2) => bitptr_di <= bitptr_do + ptradrs(bitRAM_adr_size-1 downto 0); bitptr_we <= '1'; 
            when others => null;
        end case;
    when others => null;    -- branch to next instruction (NOP)
end case;
end if;
end process decode;

--      registers and state update
update: process(clk)
begin
if (rising_edge(clk)) then
    if pcwe = '1'           then pc<=pcN;                   end if;
    if crywe = '1'          then cry<=cryn;                 end if;    -- for carry bit
    if accwe = '1'          then acc<=accn;                 end if;    -- for accumulator bit
    if rstack_we = '1'      then rstack_ptr<=rstack_ptrn;   end if;
end if;
end process update;

end RTL;

