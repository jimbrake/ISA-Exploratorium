----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		James C Brakefield
-- 
-- Create Date:     01/09/2017 
-- Design Name:		LEM4_9p 
-- Module Name:     constants - Behavioral 
-- Project Name:	LEM4_9
-- Target Devices:  xilinx Spartan-6 chip, Avent micro-board
-- Tool versions:	ISE14.9
-- Description:	Soft core processor with 9-bit instructions and 4-bit data
--		Single digit at a time "accumulator instructions to/from data RAM.
--		Supports 64-2048 word instruction ROM and 16-32 digits of data RAM.  IO mapped to data RAM locations.
--		Parameterization: return address stack depth (4-32), instruction address size (6-11) &
--		 data RAM size (16-32).  Shorter/smaller values reduce LUT counts.
--      Program ROM is dual port so extended instructions do not require a second read cycle (all inst take one clock!)
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created from LEM4_9ptr
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

entity LEM4_9 is Port (    -- 4-bit soft core processor using 2Kx9 block RAM for program
    CLOCK_Y3    : in STD_LOGIC;        -- 100MHz master clock, fully synchronous design
----      Test bench signals
--     PC_tb          : out  std_logic_vector(prog_adr_size-1 downto 0);
--     inst_tb        : out  std_logic_vector(inst_size-1 downto 0);
--     rstack_ptr_tb  : out  std_logic_vector(rtn_ptr_size-1 downto 0);
--     Acc_tb         : out  std_logic_vector(digit_size-1 downto 0);
--     Cry_tb         : out  std_logic;
--     bin_bcd_tb     : out  std_logic;
--     digitRAM_we_tb : out  std_logic;
--     digitRAM_adr_tb: out  std_logic_vector(digitRAM_adr_size-1 downto 0);
--     digitRAM_DI_tb : out  std_logic_vector(digit_size-1 downto 0);
--     digitRAM_DO_tb : out  std_logic_vector(digit_size-1 downto 0);
--  # User DIP switches
    GPIO_DIP1    : in   STD_LOGIC:='0';
    GPIO_DIP2    : in   STD_LOGIC:='0';
--  # User LEDs			
    GPIO_LED1   : out  STD_LOGIC;   -- LOC = A17 high = lit
    GPIO_LED2   : out  STD_LOGIC;   -- LOC = C16 high = lit    
    GPIO_LED3   : out  STD_LOGIC;  
    GPIO_LED4   : out  STD_LOGIC);  
end LEM4_9;

architecture RTL of LEM4_9 is

--	N suffix indicates new value, eg pc is current pc, pcN is new/next PC
signal clk  : std_logic;                            -- full speed clock (eg after the PLL)
signal acc 	: std_logic_vector(digit_size-1 downto 0):=(others => '0');	-- accumulator digit
signal accn : std_logic_vector(digit_size-1 downto 0);	                -- next accumulator digit
signal accx,accx1,accx2     : std_logic_vector(digit_size downto 0);	-- accumulator adder output, binary sum, BCD sum if carry
signal acci                 : std_logic_vector(digit_size downto 0);	-- acc or +1 or -1 input to digit adder
--signal acci,acci1,acci2     : std_logic_vector(digit_size downto 0);	-- memory inc/dec, BCD inc/dec
--signal bbrc                 : std_logic_vector(2 downto 0);	            -- bin_bcd & rbit & cry 
signal accwe 				: std_logic;           	-- accumulator update enable
signal cry                  : std_logic:='0';       -- carry bit
signal cryn, crywe          : std_logic;            -- carry bit next & enable
signal bin_bcd              : std_logic:='0';       -- binary/BCD digit addition status bit: bin=0, BCD=1
signal bin_bcdn, bin_bcdwe  : std_logic;            -- binary/BCD digit addition next & write enable
signal pcwe                 : std_logic;            -- PC update enable    
signal pc : std_logic_vector(prog_adr_size-1 downto 0):=(others => '1');-- program counter
signal pcn: std_logic_vector(prog_adr_size-1 downto 0);                 -- next program counter

--  instruction field names
signal opcode	: std_logic_vector(2 downto 0);     -- main op-code
signal rbit	    : std_logic;                        -- "replace" bit
signal adr_ops  : std_logic_vector(2 downto 0);     -- branch/pointer op-codes
signal instadrs : std_logic_vector(10 downto 0);    -- extended inst program ROM address field
signal digitadr : std_logic_vector(4 downto 0);     -- absolute digit address

--      2R port block RAM for instructions
type instrom_type is array (prog_size-1 downto 0) of std_logic_vector (inst_size-1 downto 0);   -- instruction memory type              
signal instROM : instrom_type:= (                                               -- instruction memory & initialization
--          test each instruction once or more
op_SETC,op_SETC,   -- in case PC starts at 1
-- 0x02
op_CALL,"000000110",op_JMP,"000000100",                 -- loop forever on return/faults
--          conditional branch test
-- 0x06
op_CLRC,op_JCC,"000001010",op_RTN,                      -- return/error if carry set
-- 0x0a
op_NOTC,op_JCS,"000001110",op_RTN,                      -- return/error if carry clear
-- 0x0e
op_SETC,op_JCS,"000010010",op_RTN,                      -- return/error if carry clear
-- 0x12
op_INTA OR "000001111",op_JANZ,"000010110",op_RTN,      -- return/error if acc zero
-- 0x16
op_CMPA,op_JAZ,"000011010",op_RTN,                      -- return/error if acc not zero
--          shift/rotate tests
-- 0x1a
op_INTA OR "000000011",op_ASR,op_ASR,op_JAZ,"000100000",op_RTN,                             -- arithmetic shift right
-- 0x20
op_INTA OR "000001100",op_ASR,op_ASR,op_CMPA,op_JAZ,"000100111",op_RTN,                     -- binary complement
-- 0x27,
op_INTA OR "000001100",op_ASL,op_ASL,op_JAZ,"000101101",op_RTN,                             -- arithmetic shift left
-- 0x2d
op_CLRC,op_INTA OR "000001000",op_RLAC,op_JAZ,"000110011",op_RTN,op_JCS,"000110110",op_RTN,  -- rotate left through C
-- 0x36
op_CLRC,op_INTA OR "000000001",op_RRAC,op_JAZ,"000111100",op_RTN,op_JCS,"000111111",op_RTN,  -- rotate right through C
-- 0x3f
op_INTA OR "000001100",op_ST OR "000000110",op_RLA,op_RLA,op_ROR OR "000000110",op_SETC,op_INCM OR "000000110",op_LD OR "000000110",
op_JAZ,"001001010",op_RTN,op_JCS,"001001101",op_RTN,                    -- rotate left
-- 0x4d
op_INTA OR "000001010",op_ST OR "000000110",op_RRA,op_ROR OR "000000110",op_SETC,op_INCM OR "000000110",op_LD OR "000000110",
op_JAZ,"001010111",op_RTN,op_JCS,"001011010",op_RTN,                    -- rotate right
--          two operand tests
-- 0x5a
op_SETC,op_INTA OR "000001111",op_ST OR "000000110",op_INCM OR "000000110",op_LD OR "000000110",
op_JAZ,"001100010",op_RTN,op_JCS,"001100101",op_RTN,                    -- test load/store and increment
-- 0x65
op_INTA OR "000000101",op_ST OR "000000110",op_INTA OR "000000011",op_RXOR OR "000000110",op_INTA OR "000000110",op_XOR OR "000000110",op_JAZ,"001101110",op_RTN,  -- test XOR
-- 0x6e
op_INTA OR "000000101",op_ST OR "000000110",op_INTA OR "000000011",op_ROR OR "000000110",op_INTA OR "000000111",op_XOR OR "000000110",op_JAZ,"001110111",op_RTN,   -- test OR
-- 0x77
op_INTA OR "000001010",op_STC OR "000000110",op_INTA OR "000000011",op_RAND OR "000000110",op_INTA OR "000000001",op_XOR OR "000000110",op_JAZ,"010000000",op_RTN, -- test STC and AND
-- 0x80
op_CALL,"010000100",op_JMP,"010001010",op_CALL,"010000111",op_RTN,op_CALL,"010001001",op_RTN,                                                                       -- test nested calls
-- 0x8a, 
op_CLRC,op_INTA OR "000000101",op_ST OR "000000110",op_INTA OR "000001011",op_ADC OR "000000110",op_JCS,"010010010",op_RTN,op_JAZ,"010010101",op_RTN,               -- test ADC
-- 0x95, 
op_INTA OR "000001010",op_RADC OR "000000110",op_LD OR "000000110",op_JCS,"010011011",op_RTN,op_JAZ,"010011110",op_RTN,                                             -- test RADC
--          BCD tests
-- 0x9e
op_BCD,op_SETC,op_INTA OR "000001001",op_ST OR "000000110",op_INCM OR "000000110",op_LD OR "000000110",
op_JAZ,"010100111",op_RTN,op_JCS,"010101010",op_RTN,                    -- test BCD INCM
-- 0xaa
op_CLRC,op_INTA OR "000000101",op_ST OR "000000110",op_ADC OR "000000110",
op_JAZ,"010110001",op_RTN,op_JCS,"010110100",op_RTN,                    -- test BCD ADC
-- 0xb4
op_INTA OR "000000110",op_CMPA,op_ST OR "000000110",op_INTA OR "000000011",op_XOR OR "000000110",op_JAZ,"010111100",op_RTN,  -- test BCD complement
-- 0xbc
op_RTN,     -- end of tests

----      BCD 7 digit counter to LEDs
---- 0x00
--op_SETC,op_BCD,op_INCM OR "000001000",
--op_INCM OR "000000111",op_INCM OR "000000110",op_INCM OR "000000101",op_INCM OR "000000100",
--op_INCM OR "000000011",op_INCM OR "000000010",op_INCM OR "000000001",
--op_JMP,"000000000",
OTHERS => "000000000");
signal inst, nxt_inst       : std_logic_vector(inst_size-1 downto 0);           -- registered readouts
signal instadr, instadr_p1  : std_logic_vector(prog_adr_size-1 downto 0);       -- instruction addresses or PC, PC+1
signal instROMwe            : std_logic;                                        -- used to invoke a dual port block ROM

--      1RW port LUT ram for return address stack
type rstack_ram_type is array (rtn_stack_size-1 downto 0) of std_logic_vector (prog_adr_size-1 downto 0);
signal rstack_ram : rstack_ram_type;                                            -- return stack LUT ram
signal rstack_ptr : std_logic_vector (rtn_ptr_size-1 downto 0):=(others => '0');-- pointer into return stack
signal rstack_ptrn, rstack_ptrx : std_logic_vector (rtn_ptr_size-1 downto 0);   -- new pointer & LUT address pointer
signal rstack_do, rstack_di : std_logic_vector (prog_adr_size-1 downto 0);      -- return addresses in & out of stack
signal rstack_we : std_logic;                                                   -- enable write return adr to return stack

--      1RW port LUT RAM for digit ram file
type digitRAM_type is array (digitRAM_size-1 downto 0) of std_logic_vector(digit_size-1 downto 0);	-- digit data ram type
signal digitRAM : digitRAM_type:=(others =>"0000");                             -- digit data ram
signal digitRAM_DI, digitRAM_DO: std_logic_vector(digit_size-1 downto 0);       -- digit data ram IOs
signal digitRAM_adr: std_logic_vector(digitRAM_adr_size-1 downto 0);            -- digit data ram addresses
signal digitRAM_we : std_logic;

begin
----  Test bench signal assignments
--PC_tb           <=PC;
--inst_tb         <=inst;
--rstack_ptr_tb   <=rstack_ptr;
--bin_bcd_tb      <=bin_bcd;
--digitRAM_we_tb  <=digitRAM_we;
--digitRAM_adr_tb <=digitRAM_adr;
--digitRAM_DI_tb  <=digitRAM_DI;
--digitRAM_DO_tb  <=digitRAM_DO;
--Acc_tb          <=acc;
--cry_tb          <=cry;

--  relay the clock, TBD: PLL clock generation
clk<=CLOCK_Y3;

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

--      1RW port LUT RAM for digit ram
process (clk)
begin
if rising_edge(clk) then
    if (digitRAM_we = '1') then
        digitRAM(conv_integer(digitRAM_adr)) <= digitRAM_DI;
        if digitRAM_adr = "0001" then GPIO_LED1 <= digitRAM_DI(0); end if;    -- map digit ram location to LED
        if digitRAM_adr = "0001" then GPIO_LED2 <= digitRAM_DI(1); end if;    -- map digit ram location to LED
        if digitRAM_adr = "0001" then GPIO_LED3 <= digitRAM_DI(2); end if;    -- map digit ram location to LED
        if digitRAM_adr = "0001" then GPIO_LED4 <= digitRAM_DI(3); end if;    -- map digit ram location to LED
    end if;
end if;
end process;
with digitRAM_adr select
--    digitRAM_DO <= ("00" & GPIO_PB2 & GPIO_PB1) when "0000",         -- map push button to bit ram read location
    digitRAM_DO <= ("00" & GPIO_DIP2 & GPIO_DIP1) when "0000",         -- map push button to bit ram read location
                  digitRAM(conv_integer(digitRAM_adr)) when others;

--		        parse the instruction (eg give names to instruction fields)
opcode	<= inst(8 downto 6);                        -- main op-code
rbit	<= inst(5);                                 -- "replace" bit
adr_ops <= inst(4 downto 2);                        -- branch/pointer op-codes
instadrs<= inst(1 downto 0) & nxt_inst(8 downto 0); -- extended inst program ROM address field
digitadr<= inst(4 downto 0);                        -- five-bit digit address

--      ROM/RAM connects
--instadr<=pcn; instadr_p1<=pcn+1;
instadr <= NOT pcn; instadr_p1 <= NOT (pcn+1);      -- Spartan 6 hack
digitRAM_adr <= digitadr(digitRAM_adr_size-1 downto 0);
--      binary/BCD adder
accx1 <= acci + ('0' & digitRAM_DO) + cry;          -- binary summ
accx2 <= accx1 + "00110";                           -- BCD with carry out sum
    
--      instruction decode and implementation
decode: process(inst,nxt_inst,instrom,pc,acc,accx,accx1,accx2,acci,cry,bin_bcd,
                opcode,rbit,adr_ops,instadrs,digitadr,
                rstack_ptr,rstack_do,digitRAM_do)
begin

--		default signal values
pcn<=pc+1; pcwe<='1'; if (opcode = "111" AND rbit = '1') then pcn <= pc+2; end if;
accn<="0000"; cryn<='0'; accwe<='0'; crywe<='0';
digitRAM_we<='0'; digitRAM_DI <="0000";
rstack_ptrx<=rstack_ptr; rstack_we<='0'; rstack_di <= pc+2; rstack_ptrn <= rstack_ptr - 1; -- only used by CALL & RTN, so defaults arranged for one of the two
instROMwe<='0';
bin_bcdn<='1'; bin_bcdwe<='0';
accx <= accx1; if (bin_bcd = '1') AND (accx1 > "01001") then accx <= accx2; end if;
--acci <= ('0' & digitRAMw_DO) + cry; if (rbit = '1') then acci <= ('0' & digitRAMw_DO) + "01111" + cry; end if;
acci <= '0' & acc;

if rbit = '0' then  --      write to accumulator instructions instruction implementation 
case opcode is
    when op_LD  (8 downto 6) => accn<=        digitRAM_DO;         accwe<='1';
    when op_LDC (8 downto 6) => if bin_bcd = '0' then accn <= NOT digitRAM_DO; else accn <= (NOT digitRAM_DO) + "1010"; end if; accwe<='1';
    when op_AND (8 downto 6) => accn<=acc AND digitRAM_DO;         accwe<='1';
    when op_OR  (8 downto 6) => accn<=acc OR  digitRAM_DO;         accwe<='1';
    when op_XOR (8 downto 6) => accn<=acc XOR digitRAM_DO;         accwe<='1';
    when op_ADC (8 downto 6) => accwe<='1';       crywe<='1';                accn<=accx(digit_size-1 downto 0);        cryn<=accx(digit_size);
    when op_INCM(8 downto 6) => digitRAM_we<='1'; crywe<='1'; acci<="00000"; digitRAM_DI<=accx(digit_size-1 downto 0); cryn<=accx(digit_size);
    when op_MACS(8 downto 6) =>  
      if inst(4) = '0' then accn <= inst(digit_size-1 downto 0);                                   accwe <= '1'; else       -- op_INTA
        case inst(3 downto 0) is        -- 0NNNN or 10ACC or 11xxB: init. A; complement A & complement/clear/set C; set binary or BCD digit addition, shift/rotate
            when "0000" => pcn <= rstack_do; rstack_ptrn <= rstack_ptr + 1; rstack_we <= '1';                               -- op_RTN
            when "0001" => cryn <= NOT cry; crywe <= '1';                                                                   -- op_NOTC
            when "0010" => cryn <= '0';     crywe <= '1';                                                                   -- op_CLRC
            when "0011" => cryn <= '1';     crywe <= '1';                                                                   -- op_SETC
            when "0100" => if bin_bcd = '0' then accn <= NOT acc; else accn <= (NOT acc) + "1010"; end if;    accwe <= '1'; -- op_CMPA
            when "0101" => cryn <= NOT cry; crywe <= '1'; accwe <= '1'; if bin_bcd = '0' then accn <= NOT acc; else accn <= (NOT acc) + "1010"; end if; -- op_CMPA | op_NOTC
            when "0110" => cryn <= '0';     crywe <= '1'; accwe <= '1'; if bin_bcd = '0' then accn <= NOT acc; else accn <= (NOT acc) + "1010"; end if; -- op_CMPA | op_SCT0
            when "0111" => cryn <= '1';     crywe <= '1'; accwe <= '1'; if bin_bcd = '0' then accn <= NOT acc; else accn <= (NOT acc) + "1010"; end if; -- op_CMPA | op_SCT1
            when "1000" => bin_bcdn <= '0'; bin_bcdwe <= '1';                                                               -- op_BIN
            when "1001" => bin_bcdn <= '1'; bin_bcdwe <= '1';                                                               -- op_BCD
            when "1010" => accn <= acc(digit_size-2 downto 0) & '0';                                          accwe <= '1'; -- op_ASL
            when "1011" => accn <= acc(digit_size-1) & acc(digit_size-1 downto 1);                            accwe <= '1'; -- op_ASR
            when "1100" => accn <= acc(digit_size-2 downto 0) & acc(digit_size-1);                            accwe <= '1'; -- op_RLA
            when "1101" => accn <= acc(0) & acc(digit_size-1 downto 1);                                       accwe <= '1'; -- op_RRA
            when "1110" => accn <= acc(digit_size-2 downto 0) & cry; cryn <= acc(digit_size-1); crywe <= '1'; accwe <= '1'; -- op_RLAC
            when "1111" => accn <= cry & acc(digit_size-1 downto 1); cryn <= acc(0);            crywe <= '1'; accwe <= '1'; -- op_RRAC
            when others=> null;
        end case;
      end if;
    when others => null;
end case;
else               --       write to bit RAM (replace) instructions instruction implementation
case opcode is
    when op_ST  (8 downto 6) => digitRAM_DI<=               acc;            digitRAM_we<='1';
    when op_STC (8 downto 6) => if bin_bcd = '0' then digitRAM_DI<=NOT acc; else digitRAM_DI<=(NOT acc) + "1010"; end if; digitRAM_we<='1';
    when op_RAND(8 downto 6) => digitRAM_DI<=digitRAM_DO AND acc;           digitRAM_we<='1';
    when op_ROR (8 downto 6) => digitRAM_DI<=digitRAM_DO OR  acc;           digitRAM_we<='1';
    when op_RXOR(8 downto 6) => digitRAM_DI<=digitRAM_DO XOR acc;           digitRAM_we<='1';
    when op_RADC(8 downto 6) => digitRAM_we<='1'; crywe<='1';               digitRAM_DI<=accx(digit_size-1 downto 0); cryn <= accx(digit_size);
    when op_DECM(8 downto 6) => digitRAM_we<='1'; crywe<='1'; acci<="01111"; digitRAM_DI<=accx(digit_size-1 downto 0); cryn <= accx(digit_size);
    when op_CALL(8 downto 6) => 
        case adr_ops is
            when op_CALL(4 downto 2) => pcn <= instadrs(prog_adr_size-1 downto 0); rstack_ptrx <= rstack_ptr - 1; rstack_we <= '1';
            when op_JMP (4 downto 2) => pcn <= instadrs(prog_adr_size-1 downto 0);
            when op_JAZ (4 downto 2) => if acc  = "0000" then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JANZ(4 downto 2) => if acc /= "0000" then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JCC (4 downto 2) => if cry = '0'     then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when op_JCS (4 downto 2) => if cry = '1'     then pcn <= instadrs(prog_adr_size-1 downto 0); end if;
            when others => null;
        end case;
    when others => null;
end case;
end if;
end process decode;

--      registers and state update
update: process(clk)
begin
if (rising_edge(clk)) then
    if pcwe = '1'           then pc<=pcn;                   end if;
    if crywe = '1'          then cry<=cryn;                 end if;    -- for carry bit
    if accwe = '1'          then acc<=accn;                 end if;    -- for accumulator bit
    if bin_bcdwe = '1'      then bin_bcd <= bin_bcdn;       end if;    -- for binary/BCD digit add mode
    if rstack_we = '1'      then rstack_ptr<=rstack_ptrn;   end if;    -- update return stack pointer
end if;
end process update;

end RTL;

