--	roc32min_regfile	32x32 LUT RAM register file with
--	independent port for residue register
--	One write port and four read ports

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.constants.ALL;

entity regfile is
    port (clk   : in std_logic;
          rwe   : in std_logic;	-- data in write enable
		  reswe : in std_logic; -- residue register update enable
          ra0   : in std_logic_vector(4 downto 0); -- also address of write port
          ra1   : in std_logic_vector(4 downto 0);
          ra2   : in std_logic_vector(4 downto 0);
          ra3   : in std_logic_vector(4 downto 0);
          di    : in std_logic_vector(31 downto 0);
          resdi : in std_logic_vector(31 downto 0);
          do0   : out std_logic_vector(31 downto 0);
          do1   : out std_logic_vector(31 downto 0);
          do2   : out std_logic_vector(31 downto 0);
          do3   : out std_logic_vector(31 downto 0);
          res   : out std_logic_vector(31 downto 0));
end regfile;

architecture syn of regfile is
    type ram_type is array (31 downto 0) of std_logic_vector (27 downto 0);
    signal RAM : ram_type;
	signal pcD  : std_logic_vector(31 downto 0);
	signal resD : std_logic_vector(31 downto 0);
begin

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (rwe = '1')   then RAM(to_integer(unsigned(ra0))) <= di; end if;
            if (reswe = '1') or (ra0 = RESADR) then resD <= resdi; end if;
        end if;
    end process;

    with ra0 select do0 <= res when RESADR, RAM(to_integer(unsigned(ra0))) when others;
    with ra1 select do1 <= res when RESADR, RAM(to_integer(unsigned(ra1))) when others;
    with ra2 select do2 <= res when RESADR, RAM(to_integer(unsigned(ra2))) when others;
    with ra3 select do3 <= res when RESADR, RAM(to_integer(unsigned(ra3))) when others;
	res <= resD;
end syn;
