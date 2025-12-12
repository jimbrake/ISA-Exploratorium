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
	signal ifg,id: std_logic_vector(3 downto 0);				-- instruction flag & digit
	signal s: std_logic_vector(3 downto 0);					-- write digit
	signal we:	std_logic;											-- write enable
	signal pc_oe,b_oe: std_logic;									-- PC & B share same memory port
	signal zero,carry,sign,interrupt: std_logic;				-- status register
	type state is (ldid,ldim0,ldim1,ldim2,ldifg,exec,ldr0,ldr1,ldr2,str0,str1,str2,adi0,adi1,adi2);
	signal st: state;
begin
--		video port
video: vga_video port map(rst=>rst, vclk=>vclk, vport=>vport, hsync_n=>hsync_n, vsync_n=>vsync_n, blank_n=>blank_n, vdata=>f, r=>vr, g=>vg, b=>vb);
bcdinc1: component bcd3_inc port map(a=>a,r=>aa);
bcdinc2: component bcd3_inc port map(a=>b,r=>bb);
bcdinc3: component bcd3_inc port map(a=>c,r=>cc);
bcdinc4: component bcd3_inc port map(a=>pc,r=>pcc);
bcddec1: component bcd3_dec port map(a=>l,r=>ll);

--		output signals
aport <= a;
b1port <= b when b_oe  = '1' else "ZZZZZZZZZZZZ";
b2port <= pc when pc_oe = '1' else "ZZZZZZZZZZZZ";
cport <= c;
sport <= s;
weport_n <= NOT we OR NOT clk;

process (clk, rst)
begin
	if rst='1' then
		st		<= ldid;
		pc_oe <= '1';
		b_oe  <= '0';
		we		<= '0';
		s		<= "0000";
		zero	<= '0';
		carry <= '0';
		sign	<= '0';
		interrupt <= '0';
	elsif clk'event and clk='1' then
		case st is
			when ldid  =>
				case e is
					when "1010" => pc<=a; imm<=pcc; id<="0000"; st<=ldr0;	-- load A indirect
					when "1011" => pc<=b; imm<=pcc; id<="0001"; st<=ldr0;	-- load B indirect
					when "1100" => pc<=c; imm<=pcc; id<="0010"; st<=ldr0;	-- load C indirect
					when "1101" => pc<=l; imm<=pcc; id<="0011"; st<=ldr0;	-- load L indirect
					when "1110" => id<="0100"; st<=ldr0;	-- jump indirect
					when "1111" => pc<=l;	-- return from L
					when others => id<=e; st<=ldim0;									-- go on to next inst digit
					end case;
			when ldim0 => 
				case e is
					when "1010" => pc<=pcc; pc_oe<=e(0); b_oe<= not e(0); ifg<="0000"; st<= exec;	-- move inst
					when "1011" => pc<=pcc; pc_oe<=e(0); b_oe<= not e(0); ifg<="0001"; st<= exec;	-- add/sub inst
					when "1100" => pc<=pcc; pc_oe<=e(0); b_oe<= not e(0); ifg<="0010"; st<= exec;	-- compare/misc inst
					when "1101" => pc<=pcc;	id<="0000; st<=ldid; -- nop
					when "1110" => pc<=pcc;	id<="0000; st<=ldid;	-- nop
					when "1111" => pc<=pcc;	id<="0000; st<=ldid;	-- nop
					when others => pc<=pcc; imm(3 downto 0)<=e; st<=ldim1;		-- go on to next inst digit
					end case;
			when ldim1 =>
				case e is
					when "1010" => pc<=pcc; c<='0'; st<=adi0; ifg<=e;				-- add immediate to register
					when "1011" => pc<=pcc; c<='1'; st<=adi0; ifg<=e;				-- subtract imm from register
					when "1100" => pc<=pcc; c<='1'; st<=adi0; ifg<=e;				-- compare imm with register
					when "1101" => pc<=pcc; st<=ldid;									-- move immediate to register
						case id is
							when "0000" => a<="00000000" & e;
							when "0001" => b<="00000000" & e;
							when "0010" => c<="00000000" & e;
							when "0011" => l<="00000000" & e;
							when "0100" => pc<="00000000" & e;
							when others => null;
							end case;
					when "1110" => pc<=pcc; st<=ldr0;		-- load register absolute
					when "1111" => pc<=pcc; st<=str0;		-- store register absolute
					when others => imm(7 downto 4)<=e; st<=ldim2; end if;			-- go on to next inst digit
					end case;
			when ldim2 => pc<=pcc; if e>="1010"
										then ifg<=e; st<=exec;
										else imm(11 downto 8)<=e; st<=ldif; end if;	-- go on to next inst digit
			when ldifg  => pc<=pcc; ifg<=e; st<=exec;
			--	imm & pc swapped for ldrx's
			when ldr0  => pc<=pcc; st<=ldr1;
								if id(2 downto 0)="000" then a(3 downto 0)<= e; end if;
								if id(2 downto 0)="001" then b(3 downto 0)<= e; end if;
								if id(2 downto 0)="010" then c(3 downto 0)<= e; end if;
								if id(2 downto 0)="011" then l(3 downto 0)<= e; end if;
								if id(2 downto 0)="100" then imm(3 downto 0)<= e; end if;
			when ldr1  => pc<=pcc; st<=ldr2;
								if id(2 downto 0)="000" then a(7 downto 4)<= e; end if;
								if id(2 downto 0)="001" then b(7 downto 4)<= e; end if;
								if id(2 downto 0)="010" then c(7 downto 4)<= e; end if;
								if id(2 downto 0)="011" then l(7 downto 4)<= e; end if;
								if id(2 downto 0)="100" then imm(7 downto 4)<= e; end if;
			when ldr2  => st<=ldid; ifg<="0000"; imm<="000000000000"; id<="0000";
								if id(2 downto 0)="000" then a(11 downto 8)<= e; pc<=imm; end if;
								if id(2 downto 0)="001" then b(11 downto 8)<= e; pc<=imm; end if;
								if id(2 downto 0)="010" then c(11 downto 8)<= e; pc<=imm; end if;
								if id(2 downto 0)="011" then l(11 downto 8)<= e; pc<=imm; end if;
								if id(2 downto 0)="100" then pc(11 downto 8)<= e; pc(7 downto 0)<=imm(7 downto 0); end if;
			-- imm & c swapped for strx's
			when str0  => c<=cc; we<='1'; st<=str1;
								if id="000" then s<=a(3 downto 0); end if;
								if id="001" then s<=b(3 downto 0); end if;
								if id="010" then s<=imm(3 downto 0); end if;
								if id="011" then s<=l(3 downto 0); end if;
								if id="100" then s<=pc(3 downto 0); end if;
			when str1  => c<=cc; we<='1'; st<=str2;
								if id="000" then s<=a(7 downto 4); end if;
								if id="001" then s<=b(7 downto 4); end if;
								if id="010" then s<=imm(7 downto 4); end if;
								if id="011" then s<=l(7 downto 4); end if;
								if id="100" then s<=pc(7 downto 4); end if;
			when str2  => c<=imm; we<='1'; st<=ldid; ifg<="0000"; imm<="000000000000";
								if id="000" then s<=a(11 downto 8); end if;
								if id="001" then s<=b(11 downto 8); end if;
								if id="010" then s<=imm(11 downto 8); end if;
								if id="011" then s<=l(11 downto 8); end if;
								if id="100" then s<=pc(11 downto 8); end if;
			when exec  => 
				case id is
					when "1000" =>	-- load register absolute
						if ifg<="0100" then st<=ldr0; pc<=imm; imm<=pc; else st<=ldid; ifg<="0000"; imm<="000000000000"; end if;
					when "1001" => -- store register absolute
						if ifg<="0100" then st<=str0; c<=imm; imm<=c; else st<=ldid; ifg<="0000"; imm<="000000000000"; end if;
					when others=> 
						case ifg is
							when "1010"=> -- add/subtract
								st<=arith; pc_oe<=id(0); b_oe<= not id(0);
							when "1011"=> -- move
								st<=move;  pc_oe<=id(0); b_oe<= not id(0);
							when "1100"=> -- conditional branch
								case id(2 downto 0) is
									when "000"=> if carry='1' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "001"=> if carry='0' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "010"=> if zero='1' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "011"=> if zero='0' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "100"=> if sign='1' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "101"=> if sign='0' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "110"=> if zero='0' and sign='0' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									when "111"=> if zero='1' or sign='1' then pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
									end case;
							when "1101"=> -- call
								l<=pc; pc<=imm; st<=ldid; ifg<="0000"; imm<="000000000000";
							when "1110"=> -- sob
								if l/="00000000000" then l<=ll; pc<=imm; end if; st<=ldid; ifg<="0000"; imm<="000000000000";
							when "1111"=> -- load register immediate
								null;
							when others=> st<=ldid; ifg<="0000"; imm<="000000000000";
							end case;
					end case;
			when others=> null;
			end case;
	end if;
end process;

end bcd_1;
