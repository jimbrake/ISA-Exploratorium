--  acc18_18abs.vhd     18 bit accumulator uC design with no index registers (absolute addressing only)
--  return stack, frame and stack data memory pointers
--  (c) James Brakefield, 2009

------      64x18 single port RAM with async read (distributed RAM)
library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity async_ram64x18 is port(
    clk: in std_logic;
--    en: in std_logic;
    we: in std_logic;
    a: in std_logic_vector(5 downto 0);
    di: in std_logic_vector(17 downto 0);
    do: out std_logic_vector(17 downto 0));
end async_ram64x18;
architecture arch3 of async_ram64x18 is
    type ram_type is array(63 downto 0) of std_logic_vector(17 downto 0);
    signal RAM: ram_type;
begin
    process(clk)
    begin
        if clk'event and clk='1' then
--            if en = '1' then
                if we='1' then RAM(conv_integer(a))<=di; end if;
--            end if;
        end if;
    end process;
    do <= RAM(conv_integer(a));
end arch3;

------      1024x18 single port RAM with sync read (block RAM)
library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity sync_ram1024x18 is port(
    clk: in std_logic;
--    en: in std_logic;
    we: in std_logic;
    a: in std_logic_vector(9 downto 0);
    di: in std_logic_vector(17 downto 0);
    do: out std_logic_vector(17 downto 0));
end sync_ram1024x18;
architecture arch4 of sync_ram1024x18 is
    type ram_type is array(1023 downto 0) of std_logic_vector(17 downto 0);
    signal RAM: ram_type;
    signal read_a: std_logic_vector(9 downto 0);
begin
    process(clk)
    begin
        if clk'event and clk='1' then
--            if en = '1' then
                if we='1' then RAM(conv_integer(a))<=di; end if;
--            end if;
        read_a <= a;
        end if;
    end process;
    do <= RAM(conv_integer(read_a));
end arch4;


library ieee;
use ieee.std_logic_arith.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.definitions.all;

entity acc18_18abs is port(
    clk, rst:    in std_logic;   --  clock, sync reset
    start, halt: in std_logic;
--  program RAM interface, this side is 18-bits wide by up to 2**12 words
    pmem_adr:    out std_logic_vector(11 downto 0); -- address of mem to be read or written
    pmem_we:     out std_logic;          -- write enable, active high
    pmem_out:    out std_logic;           -- data out, registered writes
--  data RAM interface, this side is 18-bits wide by up to 2**9 words
    dmem_adr:    out std_logic_vector(8 downto 0); -- address of mem to be read or written
    dmem_we:     out std_logic;          -- write enable, active high
    dmem_out:    out std_logic           -- data out, registered writes
    );
end entity acc18_18abs;

architecture behav of acc18_18abs is
--type state_type is (              -- ? states
--     halt,   -- wait for start signal
--     fetch);    -- cycle of reading instruction RAM
--     ,     -- wait for start bit or send one depending on message mode
--      bits,  -- bit sequences in various message modes,
--     T0,Tn, CRC, parity, ack);    -- termination bits and message trailer
--attribute enum_encoding of enum_t : type is "one-hot";
--attribute enum_encoding of enum_t : type is "1-hot";
--attribute enum_encoding of enum_t : type is "one hot";
--attribute enum_encoding of enum_t : type is "gray";
--attribute enum_encoding of enum_t : type is "01 10 11";
signal ir,irr: std_logic_vector(17 downto 0);   -- instruction register & instruction RAM output
signal cc: std_logic_vector(17 downto 14);      -- condition code field
signal inst: std_logic_vector(13 downto 9);     -- op-code field
signal nxadr: std_logic_vector(8 downto 0);     -- ir(8..0), data read/write address
signal pc, nxpc: std_logic_vector(11 downto 0); -- program counter & next pc
signal xpc: std_logic;                          -- pc update enable
signal acc, nxacc: std_logic_vector(17 downto 0);-- accumulator & next acc
signal cry, nxcry: std_logic;                   -- carry & next carry
signal acc19: std_logic_vector(18 downto 0);    -- adder output
signal xcry: std_logic;                         -- carry update enable
signal data_we2: std_logic;
signal data_in: std_logic_vector(17 downto 0);
signal nxmem: std_logic_vector(17 downto 0);    -- write data
signal memrd: std_logic_vector(17 downto 0);    -- read data
signal nxwe: std_logic;                         -- data write enable
signal ensub: std_logic_vector(17 downto 0);    -- add/subtract, all ones to subtract
signal encry: std_logic;                        -- enable carry into adder
signal mul36: std_logic_vector(35 downto 0);    -- multiplier output
signal cc_reg: std_logic_vector(8 downto 0);    -- condition code register
signal zfg, cfg, plfg, pofg, gtfg, a1sfg, odfg, ovfg: std_logic; -- condition code flags
begin

-- port maps
data_bit:   entity work.async_ram64x18 port map(
    clk  => clk,
--   en   => sig1,
    we   => nxwe,
    a    => nxadr(5 downto 0),
    di   => nxmem,
    do   => memrd);

memory: entity work.sync_ram1024x18 port map(
    clk => clk,
--  en  => vcc,
    we  => data_we2,
    a   => nxpc(9 downto 0),
    di  => data_in,
    do  => irr);

--  18 bit adder with carry out
acc19 <= ('0' & acc) + ('0' & (memrd xor ensub)) + ("0000000000000000" & (encry and cry));
--  18x18 signed multiplier
mul36    <= acc * memrd;
--  condition code flag extraction
zfg <= cc_reg(0); cfg <= cc_reg(1); plfg <= cc_reg(2); pofg <= cc_reg(3); gtfg <= cc_reg(4);
a1sfg <= cc_reg(5); odfg <= cc_reg(6); ovfg <= cc_reg(7);
--  breakout the instruction register
    cc <= ir(17 downto 14);
    inst  <= ir(13 downto 9);
    nxadr <= ir(8 downto 0);
-- instruction processing
decode: process(dly,start,memrd,acc,cry,inst,pc,ir) begin
--  default values for update enables & "nx" signals
nxdly   <= hlt;
xpc     <= '-';
nxpc        <= (others => '-');
nxwe        <= '-';
nxmem   <= (others => '-');
xacc        <= '-';
nxacc   <= (others => '-');
xcry        <= '-';
nxcry   <= '-';

--  state dispatch
    case dly is
    when hlt    =>
        if start = '1' then nxdly <= run; else nxdly <= hlt; end if;
        xacc    <= '1'; nxacc   <= (others => '0');
        xpc     <= '1'; nxpc    <= (others => '0'); -- keep PC reset
        xcry    <= '1'; nxcry   <= '0';
        nxwe    <= '0';

    when run    =>
--  op-code dispatch
if (cc = ccSKN) then
case inst(14 downto 12) is       -- ccSKA replacement opcodes
     when opLUT1 => null;
     when opLUT2 => null;
     when opLUT4 => null;
     when opLUT8 => null;
     when opLUT16 => null;
     when opBRA  =>   xpc <= '1'; nxpc <= ir(11 downto 0);
     when opCALLA => null;
     when opSHFT2 => null;
     when others => null;
end case;
elsif                            -- conditional execution test
      (cc(3 downto 1)=ccZ(3 downto 1) and (zfg xor cc(0))) or
      (cc(3 downto 1)=ccC(3 downto 1) and (cfg xor cc(0))) or
      (cc(3 downto 1)=ccPL(3 downto 1) and (plfg xor cc(0))) or
      (cc=ccSKN) or
      (cc(3 downto 1)=ccPO(3 downto 1) and (pofg xor cc(0))) or
      (cc(3 downto 1)=ccGT(3 downto 1) and (gtfg xor cc(0))) or
      (cc(3 downto 1)=ccA1S(3 downto 1) and (a1sfg xor cc(0))) or
      (cc(3 downto 1)=ccOD(3 downto 1) and (odfg xor cc(0))) then
case inst is                     -- instruction processing
when opST  =>
    nxdly<= run;
    xacc    <= '0';
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '1'; nxmem   <= acc;

when opLD  =>
    nxdly<= run;
    xacc    <= '1'; nxacc   <= memrd;
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when opLDC =>
    nxdly<= run;
    xacc    <= '1'; nxacc   <= not memrd;
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when opAND =>
    nxdly<= run;
    xacc    <= '1'; nxacc   <= acc and memrd;
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when opOR  =>
    nxdly<= run;
    xacc    <= '1'; nxacc   <= acc or memrd;
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when opXOR =>
    nxdly<= run;
    xacc    <= '1'; nxacc   <= acc xor memrd;
    xpc     <= '1'; nxpc    <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when opAD =>
    nxdly<= run;
    xacc    <= '1'; ensub <= (others => '0'); encry <= '0'; nxacc <= acc19(17 downto 0);
    xpc     <= '1'; nxpc  <= pc + 1;
    xcry    <= '1'; nxcry <= acc19(18);
    nxwe    <= '0';

when opADC =>
    nxdly<= run;
    xacc    <= '1'; ensub <= (others => '0'); encry <= '1'; nxacc <= acc19(17 downto 0);
    xpc     <= '1'; nxpc  <= pc + 1;
    xcry    <= '1'; nxcry <= acc19(18);
    nxwe    <= '0';

when opSUB =>
    nxdly<= run;
    xacc    <= '1'; ensub <= (others => '1'); encry <= '0'; nxacc <= acc19(17 downto 0);
    xpc     <= '1'; nxpc  <= pc + 1;
    xcry    <= '1'; nxcry <= acc19(18);
    nxwe    <= '0';

when opSBC =>
    nxdly<= run;
    xacc    <= '1'; ensub <= (others => '1'); encry <= '1'; nxacc <= acc19(17 downto 0);
    xpc     <= '1'; nxpc  <= pc + 1;
    xcry    <= '1'; nxcry <= acc19(18);
    nxwe    <= '0';

when opMUL =>
    nxdly<= run;
    xacc    <= '1'; nxacc <= mul36(18 downto 0);
    xpc     <= '1'; nxpc  <= pc + 1;
    xcry    <= '0';
    nxwe    <= '0';

when others => null;
end case;
end if;
    when others => null;
    end case;

end process decode;

--      all processor register updates
update: process(clk,reset) begin
if (clk'event) then
if (reset='1')        -- syncronous reset
then                  -- reset values:
    dly     <= hlt;
    acc     <= (others => '0');
    cry     <= '0';
    pc      <= (others => '0');
--      monitoring signals
    acc_cpy <= (others => '0');
    cry_cpy <= '0';
    nxdata  <= (others => '0');
    data_we <= '0';
    pc_reg  <= (others => '0');
    mem_rd  <= (others => '0');
else                   -- register updates
--      pipeline the instruction memory output
    ir <= irr;
--      state variable update
    dly     <= nxdly;
--      accumulator update
    if xacc = '1'   then acc    <= nxacc; end if;
--      update carry bit
    if xcry = '1'   then cry    <= nxcry; end if;
--      Program counter update
    if xpc = '1'    then pc <= nxpc; end if;
----    monitoring signals
    acc_cpy <= acc;
    cry_cpy <= cry;
    nxdata  <= nxmem;
    data_we <= nxwe;
    pc_reg  <= pc;
    mem_rd  <= inst & nxadr;
end if;
end if;
end process update;

end behav;

