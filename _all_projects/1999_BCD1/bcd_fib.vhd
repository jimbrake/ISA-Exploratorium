--	bcd_020331.vhd	VHDL code for very basic BCD serial computer
--	connects to 4Kx4 quad port RAM (or three 4Kx4 dual port RAMs)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity BCD is
	port(
		rst, clk:	in std_logic;
--			async RAM connections, read access time ~ 1/2 of clk period
		aport:	out std_logic_vector(11 downto 0);	-- 1st operand address
		b1port:	out std_logic_vector(11 downto 0);	-- 2nd operand address
		b2port:	out std_logic_vector(11 downto 0);	-- 2nd operand address
		cport:	out std_logic_vector(11 downto 0);	-- result address
		vport:	out std_logic_vector(11 downto 0);	-- video display address
		d,e,f:	in std_logic_vector(3 downto 0);		-- read data
		sport:	out std_logic_vector(3 downto 0);	-- write data
		weport_n:	out std_logic;								-- write strobe (low in 2nd phase of clock)
--			Video out signals (feed resitor network)
		vclk:		in std_logic;								-- video display clock
		vr,vg,vb:	out std_logic_vector(1 downto 0);	-- video bits
		hsync_n,vsync_n,blank_n:	out std_logic);		-- remainder of video out
end BCD;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

architecture bcd_1 of BCD is

component bcd_add is	-- 	BCD adder
	port(
	d,e: in std_logic_vector(3 downto 0);
	c: in std_logic;
	s: out std_logic_vector(3 downto 0);
	cc: out std_logic);
end component bcd_add;

component bcd3_inc is	-- 	three digit BCD up counter
	port(
	a: in std_logic_vector(11 downto 0);
	r: out std_logic_vector(11 downto 0));
end component bcd3_inc;

component bcd3_dec is	-- 	three digit BCD down counter
	port(
	a: in std_logic_vector(11 downto 0);
	r: out std_logic_vector(11 downto 0));
end component bcd3_dec;

component vga_video port(
		rst:	in std_logic;
		vclk:		in std_logic;								-- video display clock
		vport:	out std_logic_vector(11 downto 0);	-- video display address
		vdata:	in std_logic_vector(3 downto 0);		-- video data
		r,g,b:	out std_logic_vector(1 downto 0);	-- video bits
		hsync_n,vsync_n,blank_n:	out std_logic);		-- remainder of video out
end component;

	signal pc,pcc,a,aa,b,bb,c,cc,l,ll,imm: std_logic_vector(11 downto 0);	-- 3-digit BCD registers
	signal ifg: std_logic_vector(3 downto 0);		-- instruction flag 
	signal s,ss: std_logic_vector(3 downto 0);	-- write digit
	signal we:	std_logic;								-- write enable
	signal pc_oe,b_oe: std_logic;						-- PC & B share same memory port
	signal carry,ccarry: std_logic;					-- status register
	type state is (ldim0,ldim1,ldim2,ldifg,exec,halt);
	signal st: state;
begin
--		video port
video: vga_video port map(rst=>rst, vclk=>vclk, vport=>vport, hsync_n=>hsync_n, vsync_n=>vsync_n, blank_n=>blank_n, vdata=>f, r=>vr, g=>vg, b=>vb);
bcdinc1: component bcd3_inc port map(a=>a,r=>aa);
bcdinc2: component bcd3_inc port map(a=>b,r=>bb);
bcdinc3: component bcd3_inc port map(a=>c,r=>cc);
bcdinc4: component bcd3_inc port map(a=>pc,r=>pcc);
bcddec1: component bcd3_dec port map(a=>l,r=>ll);
bcdadd:  component bcd_add port map(d=>d,e=>e,c=>carry,s=>ss,cc=>ccarry);

--		output signals
aport <= a;
b1port <= b  when pc_oe = '0' else "ZZZZZZZZZZZZ";
b2port <= pc when pc_oe = '1' else "ZZZZZZZZZZZZ";
cport <= c;
sport <= s;
weport_n <= NOT we OR NOT clk;

process (clk, rst)
begin
	if rst='1' then
		st		<= ldid;
		pc_oe <= '1';
		we		<= '0';
		wee	<= '0';
		s		<= "0000";
		carry <= '0';
	elsif clk'event and clk='1' then
		case st is
			when halt  => null;
			when ldim0 => we<='0';
				case e is
					when "1010" => pc<=pcc; a<="000000000000"; if we='1' then c<=cc; end if;	-- LDAI
					when "1011" => pc<=pcc; b<="000000000000"; if we='1' then c<=cc; end if;	-- LDBI
					when "1100" => pc<=pcc; c<="000000000000";											-- LDCI
					when "1101" => pc<=pcc;	l<="000000000000"; if we='1' then c<=cc; end if;	-- LDLI
					when "1110" => pc<=pcc; st<=halt; 			 if we='1' then c<=cc; end if;	-- HALT
					when "1111" => pc<=pcc;	st<=exec; pc_oe<='0'; carry<='0'; if we='1' then c<=cc; end if;	-- ADDE
					when others => pc<=pcc; imm(3 downto 0)<=e; st<=ldim1; if we='1' then c<=cc; end if;		-- go on to next inst digit
					end case;
			when ldim1 =>
				case e is
					when "1010" => pc<=pcc; st<=ldim0; a<="00000000" & imm(3 downto 0);	-- LDAI
					when "1011" => pc<=pcc; st<=ldim0; b<="00000000" & imm(3 downto 0);	-- LDBI
					when "1100" => pc<=pcc; st<=ldim0; c<="00000000" & imm(3 downto 0);	-- LDCI
					when "1101" => pc<=pcc; st<=ldim0; l<="00000000" & imm(3 downto 0);	-- LDLI
					when "1110" => st<=ldim0; if l/="000000000000"								-- SOB
														then l<=ll; pc<="00000000" & imm(3 downto 0);
														else pc<=pcc; end if;
					when "1111" => pc<=pcc;	st<=exec; pc_oe<='0'; carry<='0';	-- ADDE
					when others => pc<=pcc; imm(7 downto 4)<=e; st<=ldim1;		-- go on to next inst digit
					end case;
			when ldim2 =>
				case e is
					when "1010" => pc<=pcc; st<=ldim0; a<="0000" & imm(7 downto 0);	-- LDAI
					when "1011" => pc<=pcc; st<=ldim0; b<="0000" & imm(7 downto 0);	-- LDBI
					when "1100" => pc<=pcc; st<=ldim0; c<="0000" & imm(7 downto 0);	-- LDCI
					when "1101" => pc<=pcc; st<=ldim0; l<="0000" & imm(7 downto 0);	-- LDLI
					when "1110" => st<=ldim0; if l/="000000000000"							-- SOB
														then l<=ll; pc<="0000" & imm(7 downto 0);
														else pc<=pcc; end if;
					when "1111" => pc<=pcc;	st<=exec; pc_oe<='0'; carry<='0';	-- ADDE
					when others => pc<=pcc; imm(11 downto 8)<=e; st<=ldim1;		-- go on to next inst digit
					end case;
			when ldifg  =>
				case e is
					when "1010" => pc<=pcc; st<=ldim0; a<=imm;		-- LDAI
					when "1011" => pc<=pcc; st<=ldim0; b<=imm;		-- LDBI
					when "1100" => pc<=pcc; st<=ldim0; c<=imm;		-- LDCI
					when "1101" => pc<=pcc; st<=ldim0; l<=imm;		-- LDLI
					when "1110" => st<=ldim0; if l/="000000000000"	-- SOB
														then l<=ll; pc<=imm;
														else pc<=pcc; end if;
					when "1111" => pc<=pcc;	st<=exec; pc_oe<='0'; carry<='0';	-- ADDE
					when others => pc<=pcc; st<=halt;					-- halt if more than 3 BCD digits in instruction
					end case;
			when exec  =>
				we <= '1'; if we='1' then c<=cc; end if;
				if d<"1010" then
					if e<"1010" then a<=aa; b<=bb; s<=ss; carry<=ccarry;
									else a<=aa; s<=ss; carry<=ccarry;
									end if;
				elsif e<"1010" then b<=bb; s<=ss; carry<=ccarry;
				elsif ccarry='1' then s<="0001"; carry<='0';
									else s<="1010"; a<=aa; b<=bb; st<=ldim0; pc_oe<='1';
									end if;
			when others=> null;
			end case;
	end if;
end process;

end bcd_1;
