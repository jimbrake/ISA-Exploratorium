--		vga_video.vhd		VGA controller for BCD_1
--		generates video display for 1000 digit memory
--		with VGA timing (~25.175 Mhz clock):
--		horizontal timing in clocks: 640, 24, 96, 48 (808 total) active, back porch, sync, front porch
--		vertical timing in scan lines: 480, 11, 2, 32 (525 total) active, back porch, sync, front porch

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga_video is
	port(
		rst:		in std_logic;
		vclk:		in std_logic;								-- video display clock
		vport:	out std_logic_vector(11 downto 0);	-- video display address
		vdata:	in std_logic_vector(3 downto 0);		-- video data
--			Video out signals (feed resitor network)
		r,g,b:	out std_logic_vector(1 downto 0);	-- video bits
		hsync_n,vsync_n,blank_n:	out std_logic);		-- remainder of video out
end vga_video;

architecture bcd_1 of vga_video is

signal h,v: std_logic_vector(9 downto 0);	-- horz & vert pixel counts
signal ma,mm: std_logic_vector(11 downto 0);	-- BCD counter
signal hs,vs,hblk,vblk,blnkn: std_logic;			-- syncs & blanking
signal d: std_logic_vector(3 downto 0);	-- video data
--type rom_type is array (127 downto 0) of std_logic_vector(7 downto 0);
signal rom: std_logic_vector(7 downto 0);	-- digit to pixel table

begin
	process (vclk, rst)
	begin
		if rst='1' then
			h <= "0000000001";
			v <= "0000000001";
			hs <= '0';
			vs <= '0';
			hblk <= '0';
			vblk <= '0';
			r <= "00";
			g <= "00";
			b <= "00";
			ma <= "000000000000";
			d <= "0000";
		elsif vclk'event and vclk='1' then
--	h reg
			if (h = "11--1-1---") then h <= "0000000001"; else h <= h + 1; end if;
-- v reg
			if (h = "11--1-1---") AND (v = "1-----11-1") then v <= "0000000001"; else v <= v + 1; end if;
-- hblk
			if (h = "1-1-------") then hblk <= '1'; end if;
			if (h = "0---------") then hblk <= '0'; end if;
-- vblk
			if (v = "01111----1") then vblk <= '1'; end if;
			if (v = "00--------") then vblk <= '0'; end if;
-- hs
			if (h = "1-1--11---") then hs <= '1'; end if;
			if (h = "1-11111---") then hs <= '0'; end if;
--	vs
			if (v = "-1111-1-11") then vs <= '1'; end if;
			if (v = "-1111-11-1") then vs <= '0'; end if;
-- ma reg
			if (h = "------0001") AND (v = "-------0001") then
				if vblk = '1' then ma <= "000000000000";
				else ma <= mm; end if;
				end if;
--	data reg
			if (h = "------0001") AND (v = "-------0001") then d <= vdata; end if;
-- intensify every 10th digit
			if (ma = "--------0000") AND (blnkn = '1') then g(0) <= '1'; else g(0) <= '0'; end if;
--	digit pixels
			if(blnkn = '1') then g(1) <= rom(conv_integer(v(3 downto 1))); else g(1) <= '0'; end if;
		end if;
	end process;

	process(ma)
	begin
		if (ma(3)='0') or (ma(0)='0') then mm(11 downto 4) <= ma(11 downto 4); mm(3 downto 0) <= ma(3 downto 0) + 1;
		elsif (ma(7)='0') or (ma(4)='0') then mm(11 downto 8) <= ma(11 downto 8); mm(7 downto 4) <= ma(7 downto 4) + 1; mm(3 downto 0) <= "0000";
		elsif (ma(11)='0') or (ma(8)='0') then mm(11 downto 8) <= ma(11 downto 8) + 1; mm(7 downto 0) <= "00000000";
		else mm <= "000000000000";
		end if;
	end process;

  process (d,h)
  begin
    case d & h(3 downto 1) is
--	zero
      when "0000000" => rom <= "01111000";
      when "0000001" => rom <= "10000100";
      when "0000010" => rom <= "10000100";
      when "0000011" => rom <= "10000100";
      when "0000100" => rom <= "10000100";
      when "0000101" => rom <= "10000100";
      when "0000110" => rom <= "01111000";
--	one
      when "0001000" => rom <= "00010000";
      when "0001001" => rom <= "00110000";
      when "0001010" => rom <= "00010000";
      when "0001011" => rom <= "00010000";
      when "0001100" => rom <= "00010000";
      when "0001101" => rom <= "00010000";
      when "0001110" => rom <= "00111000";
-- two
      when "0010000" => rom <= "01111000";
      when "0010001" => rom <= "10000100";
      when "0010010" => rom <= "00000100";
      when "0010011" => rom <= "00011000";
      when "0010100" => rom <= "01100000";
      when "0010101" => rom <= "10000000";
      when "0010110" => rom <= "11111100";
-- three
      when "0011000" => rom <= "01111000";
      when "0011001" => rom <= "10000100";
      when "0011010" => rom <= "00000100";
      when "0011011" => rom <= "00111000";
      when "0011100" => rom <= "00000100";
      when "0011101" => rom <= "10000100";
      when "0011110" => rom <= "01111000";
-- four
      when "0100000" => rom <= "00010000";
      when "0100001" => rom <= "00110000";
      when "0100010" => rom <= "01010000";
      when "0100011" => rom <= "11111000";
      when "0100100" => rom <= "00010000";
      when "0100101" => rom <= "00010000";
      when "0100110" => rom <= "00010000";
-- five
      when "0101000" => rom <= "11111100";
      when "0101001" => rom <= "10000000";
      when "0101010" => rom <= "11111000";
      when "0101011" => rom <= "00000100";
      when "0101100" => rom <= "00000100";
      when "0101101" => rom <= "10000100";
      when "0101110" => rom <= "01111000";
-- six
      when "0110000" => rom <= "01111100";
      when "0110001" => rom <= "10000000";
      when "0110010" => rom <= "10000000";
      when "0110011" => rom <= "11111000";
      when "0110100" => rom <= "10000100";
      when "0110101" => rom <= "10000100";
      when "0110110" => rom <= "01111000";
-- seven
      when "0111000" => rom <= "11111100";
      when "0111001" => rom <= "00000100";
      when "0111010" => rom <= "00001000";
      when "0111011" => rom <= "00010000";
      when "0111100" => rom <= "00100000";
      when "0111101" => rom <= "01000000";
      when "0111110" => rom <= "01000000";
-- eight
      when "1000000" => rom <= "01111000";
      when "1000001" => rom <= "10000100";
      when "1000010" => rom <= "10000100";
      when "1000011" => rom <= "01111000";
      when "1000100" => rom <= "10000100";
      when "1000101" => rom <= "10000100";
      when "1000110" => rom <= "01111000";
-- nine
      when "1001000" => rom <= "01111000";
      when "1001001" => rom <= "10000100";
      when "1001010" => rom <= "10000100";
      when "1001011" => rom <= "01111100";
      when "1001100" => rom <= "00000100";
      when "1001101" => rom <= "10000100";
      when "1001110" => rom <= "01111000";
-- A
      when "1010000" => rom <= "00110000";
      when "1010001" => rom <= "01001000";
      when "1010010" => rom <= "10000100";
      when "1010011" => rom <= "11111100";
      when "1010100" => rom <= "10000100";
      when "1010101" => rom <= "10000100";
      when "1010110" => rom <= "10000100";
-- B
      when "1011000" => rom <= "11111000";
      when "1011001" => rom <= "10000100";
      when "1011010" => rom <= "10000100";
      when "1011011" => rom <= "11111000";
      when "1011100" => rom <= "10000100";
      when "1011101" => rom <= "10000100";
      when "1011110" => rom <= "11111000";
--	C
      when "1100000" => rom <= "01111000";
      when "1100001" => rom <= "10000100";
      when "1100010" => rom <= "10000000";
      when "1100011" => rom <= "10000000";
      when "1100100" => rom <= "10000000";
      when "1100101" => rom <= "10000100";
      when "1100110" => rom <= "01111000";
--	D
      when "1101000" => rom <= "11111000";
      when "1101001" => rom <= "10000100";
      when "1101010" => rom <= "10000100";
      when "1101011" => rom <= "10000100";
      when "1101100" => rom <= "10000100";
      when "1101101" => rom <= "10000100";
      when "1101110" => rom <= "11111000";
--	E
      when "1110000" => rom <= "11111100";
      when "1110001" => rom <= "10000000";
      when "1110010" => rom <= "10000000";
      when "1110011" => rom <= "11110000";
      when "1110100" => rom <= "10000000";
      when "1110101" => rom <= "10000000";
      when "1110110" => rom <= "11111100";
--	F
      when "1111000" => rom <= "11111100";
      when "1111001" => rom <= "10000000";
      when "1111010" => rom <= "10000000";
      when "1111011" => rom <= "11110000";
      when "1111100" => rom <= "10000000";
      when "1111101" => rom <= "10000000";
      when "1111110" => rom <= "10000000";

      when others =>		rom <= "00000000";
    end case;
  end process;

vport <= ma;
hsync_n <= not hs;
vsync_n <= not vs;
blank_n <= blnkn;
blnkn <= not (hblk OR vblk);

end bcd_1;

