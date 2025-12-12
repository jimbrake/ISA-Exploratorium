--	bcd_count.vhd		3-digit BCD counters

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bcd_add is	-- 	BCD adder
	port(
	d,e: in std_logic_vector(3 downto 0);
	c: in std_logic;
	s: out std_logic_vector(3 downto 0);
	cc: out std_logic);
end bcd_add;

architecture bcd_addx of bcd_add is
signal r1: std_logic_vector(5 downto 0);
signal r2: std_logic_vector(5 downto 2);
signal dd,ee: std_logic_vector(4 downto 0);
begin
	process(d,e,c)
	begin
		if d>="1010" then dd<="0000"; else dd<=d; end if;
		if e>="1010" then dd<="0000"; else ee<=e; end if;
		r1 <= ('0' & dd & c) + ('0' & ee & c);
		r2 <= ('0' & r1(4 downto 2)) + "0011";
		if r1(5)='1' OR r2(5)='1' then s<=r2(4 downto 2) & r1(1); cc<='1'; else s<=r1(4 downto 1); cc<='0';
	end process;
end bcd_addx;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bcd3_inc is	-- 	three digit BCD up counter
	port(
	a: in std_logic_vector(11 downto 0);
	r: out std_logic_vector(11 downto 0));
end bcd3_inc;

architecture bcd3_incx of bcd3_inc is
begin
	process(a)
	begin
		if (a(3)='0') or (a(0)='0') then r(11 downto 4) <= a(11 downto 4); r(3 downto 0) <= a(3 downto 0) + 1;
		elsif (a(7)='0') or (a(4)='0') then r(11 downto 8) <= a(11 downto 8); r(7 downto 4) <= a(7 downto 4) + 1; r(3 downto 0) <= "0000";
		elsif (a(11)='0') or (a(8)='0') then r(11 downto 8) <= a(11 downto 8) + 1; r(7 downto 0) <= "00000000";
		else r <= "000000000000";
		end if;
	end process;
end bcd3_incx;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bcd3_dec is	-- 	three digit BCD down counter
	port(
	a: in std_logic_vector(11 downto 0);
	r: out std_logic_vector(11 downto 0));
end bcd3_dec;

architecture bcd3_decx of bcd3_dec is
begin
	process(a)
	begin
		if a(3 downto 0) /= "0000" then r(11 downto 4) <= a(11 downto 4); r(3 downto 0) <= r(3 downto 0) - 1;
		elsif a(7 downto 4) /= "0000" then r(11 downto 8) <= a(11 downto 8); r(7 downto 4) <= a(7 downto 4) - 1; r(3 downto 0) <= "1001";
		elsif a(11 downto 8) /= "0000" then r(11 downto 8) <= a(11 downto 8) - 1; r(7 downto 0) <= "10011001";
		else r <= "100110011001";
		end if;
	end process;
end bcd3_decx;
