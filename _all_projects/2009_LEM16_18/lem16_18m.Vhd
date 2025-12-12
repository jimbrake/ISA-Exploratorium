-- lem18_18m.vhd    minimized LEM16_18
-- 16-bit accumulator, 18-bit instruction
-- designed for "EDIF emulation"
-- data is bit addressed bit fields with size field in instruction
-- uses program ROM, return stack, data stack & bit addressable data RAM
-- (c) James Brakefield, 2013

library ieee;
use ieee.std_logic_arith.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.definitions.all;

--                     TOP Level Port
entity lem16_18m is port(
--  Spartan-3 board: 
--		clock(50MHz T9), sync reset (user reset L14)
--  	start & halt: BTN2: L14, BTN 1: M14
--		digit select, active low: AN3(left most), AN2, AN1, AN0 (right most)
--  	segment drive, active low: E14(top), G13(up right), N15(low right, P15(bot), R16(low left), F13(up left), N16(middle), P16(dp)
    clk, rst:    in std_logic;   	
    start, halt_sig: in std_logic;
--		program interface
	 ROM_adr: out std_logic_vector(9 downto 0);
	 ROM_dat: in std_logic_vector(17 downto 0);
--  IO interface (to 4-digit 7-segment LED display)
    digit_sel:   out std_logic_vector(3 downto 0);
    seg_sel:	  out std_logic_vector(7 downto 0)
    );
end entity lem16_18m;

architecture behav of lem16_18m is
type stack_type is array (0 to 2**RDADR_BITS-1) of std_logic_vector(RDWORD_SZ-1 downto 0);	-- simple dual port
type datram_type is array (0 to 2**DADR_BITS-1) of std_logic_vector(DWORD_SZ-1 downto 0);		-- single port, 256 bits
type inst_type is array (0 to 2**IADR_BITS-1) of std_logic_vector(IWORD_SZ-1 downto 0);		-- block ROM
type T_state is (              -- 2 states
     HLT,     -- wait for start signal
     LUT,     -- do LUT lookup read from inst memory
     RUN);    -- cycle of reading instruction RAM
signal R_TI_state, TI_nxstate: T_state;

signal I_ir: std_logic_vector(IWORD_SZ-1 downto 0);  -- instruction ROM output
signal I_cc: std_logic_vector(3 downto 0);           -- condition code field
signal I_op: std_logic_vector(5 downto 0);           -- op-code field
signal I_adr: std_logic_vector(9 downto 0);          -- ROM address
signal I_imm: std_logic_vector(7 downto 0);          -- RAM address or immediate
signal E_CC: std_logic;										  -- enable saving I_cc into R_cc(7..4)
signal C_noskip: std_logic;       -- no register updates except PC<=PC+1 if = 0
signal R_pc, A_nxpc, AA_nxpc: std_logic_vector(9 downto 0);   -- program counter & next pc & next pc temporary
signal E_pc: std_logic;                              -- pc update enable

signal R_acc, D_nxacc, D_acc: std_logic_vector(DWORD_SZ-1 downto 0);-- accumulator & next acc
signal E_acc: std_logic;                      -- accumulator update enable
signal C_nxcry: std_logic;                    -- next carry
signal E_cry: std_logic;                      -- carry update enable

signal RA_nxstk, WA_nxstk: std_logic_vector(RDADR_BITS-1 downto 0); -- Return/Data stack read/write addresses
signal D_STKrd, R_STKrd, RD_STKwt: std_logic_vector(RDWORD_SZ-1 downto 0);  -- Return/Data stack read/write signals
signal R_rtnstk_adr, R_expstk_adr: std_logic_vector(RDADR_BITS-1 downto 0);
signal A_rtnstk_adr, A_expstk_adr: std_logic_vector(RDADR_BITS-1 downto 0);
signal E_rtnstk_adr, E_expstk_adr: std_logic;

signal A_nxadr: std_logic_vector(DADR_BITS-1 downto 0); -- RAM read/write address
signal D_RAMrd: std_logic_vector(DWORD_SZ-1 downto 0);  -- RAM read data
signal E_RAMwe: std_logic_vector(DWORD_SZ-1 downto 0);  -- data write enables
signal E_DatRAMwe: std_logic;									  -- overall data write enable
signal D_RAMwtd: std_logic_vector(DWORD_SZ-1 downto 0); -- RAM write data
signal D_MSB_msk_adr, D_LSB_msk_adr: std_logic_vector(3 downto 0); -- RAM write mask ends
signal D_MSB_msk, D_LSB_msk, D_sz_msk: std_logic_vector(DWORD_SZ-1 downto 0); -- RAM write masks

signal R_cc: std_logic_vector(7 downto 0);           -- condition code register
signal CCzfg, CCcfg, CCplfg, CCpofg, CCgtfg, CCa1sfg, CCodfg, CCovfg: std_logic; -- condition code flags
signal C_cc_do_inst, cc_do_inst: std_logic;                      -- condition code & CC field match
signal E_cryin: std_logic;                           -- enable carry into adder
signal D_acc17: std_logic_vector(DWORD_SZ downto 0); -- adder output
signal D_srlRAM: std_logic_vector(DWORD_SZ-1 downto 0); -- shifted & masked RAM read data
signal D_ensub: std_logic_vector(DWORD_SZ-1 downto 0);  -- all ones for subtract
signal D_ext_imm: std_logic_vector(DWORD_SZ-1 downto 0);  -- immediate extended to 16-bits
--	RAMs
signal Rstk:	stack_type;		-- return stacks
signal Datram:	datram_type;	-- 256 bit data RAM
signal IROM:	inst_type;		-- 1Kx8 program memory

begin

--		Return stack, simple dual port
R_STKrd <= Rstk(conv_integer(R_rtnstk_adr));
Rstack: process (clk) begin
if rising_edge(clk) then if E_rtnstk_adr = '1' then Rstk(conv_integer(A_rtnstk_adr)) <= "000000" & A_nxpc; end if; 
end if;
end process Rstack;


--		Program memory, 8x1K block RAM, read only
--Iread: process (clk) begin
--if rising_edge(clk) then 
--	I_ir <= IROM(conv_integer(A_nxpc(IADR_BITS-1 downto 0)));
--end if;
--end process Iread;
--		External Program memory
I_ir <= ROM_dat;
ROM_adr <= A_nxpc;

--  breakout the instruction register
I_cc  <= I_ir(17 downto 14);
I_op  <= I_ir(13 downto 8);
I_adr <= I_ir(9 downto 0);
I_imm <= I_ir(7 downto 0);

A_nxadr <= I_imm(7 downto 4);

--		Data RAM, single port
D_RAMrd <= Datram(conv_integer(A_nxadr));
Datram_wt: process (clk) begin
if rising_edge(clk) then 
	if E_DatRAMwe = '1' then
		if E_RAMwe(0) = '1' then Datram(conv_integer(A_nxadr))(0) <= D_RAMwtd(0); end if;
		if E_RAMwe(1) = '1' then Datram(conv_integer(A_nxadr))(1) <= D_RAMwtd(1); end if;
		if E_RAMwe(2) = '1' then Datram(conv_integer(A_nxadr))(2) <= D_RAMwtd(2); end if;
		if E_RAMwe(3) = '1' then Datram(conv_integer(A_nxadr))(3) <= D_RAMwtd(3); end if;
		if E_RAMwe(4) = '1' then Datram(conv_integer(A_nxadr))(4) <= D_RAMwtd(4); end if;
		if E_RAMwe(5) = '1' then Datram(conv_integer(A_nxadr))(5) <= D_RAMwtd(5); end if;
		if E_RAMwe(6) = '1' then Datram(conv_integer(A_nxadr))(6) <= D_RAMwtd(6); end if;
		if E_RAMwe(7) = '1' then Datram(conv_integer(A_nxadr))(7) <= D_RAMwtd(7); end if;
		if E_RAMwe(8) = '1' then Datram(conv_integer(A_nxadr))(8) <= D_RAMwtd(8); end if;
		if E_RAMwe(9) = '1' then Datram(conv_integer(A_nxadr))(9) <= D_RAMwtd(9); end if;
		if E_RAMwe(10) = '1' then Datram(conv_integer(A_nxadr))(10) <= D_RAMwtd(10); end if;
		if E_RAMwe(11) = '1' then Datram(conv_integer(A_nxadr))(11) <= D_RAMwtd(11); end if;
		if E_RAMwe(12) = '1' then Datram(conv_integer(A_nxadr))(12) <= D_RAMwtd(12); end if;
		if E_RAMwe(13) = '1' then Datram(conv_integer(A_nxadr))(13) <= D_RAMwtd(13); end if;
		if E_RAMwe(14) = '1' then Datram(conv_integer(A_nxadr))(14) <= D_RAMwtd(14); end if;
		if E_RAMwe(15) = '1' then Datram(conv_integer(A_nxadr))(15) <= D_RAMwtd(15); end if;
	end if;
end if;
end process Datram_wt;

--  frame immediate into 16-bits
D_ext_imm <= "00000000" & I_imm when I_op(3) = '0' else I_imm & "00000000";

--  16 bit adder with carry out
D_acc17    <= ('0' & R_acc) +
           ('0' & (D_srlRAM xor D_ensub)) +
           ("0000000000000000" & (E_cryin and CCcfg));

--  shifted & masked RAM read data
shift_data: process (I_imm,D_RAMrd,D_sz_msk) begin
case I_imm(3 downto 0) is
when "0000" => D_srlRAM <= D_RAMrd and D_sz_msk;
when "0001" => D_srlRAM <= ('-' & D_RAMrd(15 downto 1)) and D_sz_msk;
when "0010" => D_srlRAM <= ("--" & D_RAMrd(15 downto 2)) and D_sz_msk;
when "0011" => D_srlRAM <= ("---" & D_RAMrd(15 downto 3)) and D_sz_msk;
when "0100" => D_srlRAM <= ("----" & D_RAMrd(15 downto 4)) and D_sz_msk;
when "0101" => D_srlRAM <= ("-----" & D_RAMrd(15 downto 5)) and D_sz_msk;
when "0110" => D_srlRAM <= ("------" & D_RAMrd(15 downto 6)) and D_sz_msk;
when "0111" => D_srlRAM <= ("-------" & D_RAMrd(15 downto 7)) and D_sz_msk;
when "1000" => D_srlRAM <= ("--------" & D_RAMrd(15 downto 8)) and D_sz_msk;
when "1001" => D_srlRAM <= ("---------" & D_RAMrd(15 downto 9)) and D_sz_msk;
when "1010" => D_srlRAM <= ("----------" & D_RAMrd(15 downto 10)) and D_sz_msk;
when "1011" => D_srlRAM <= ("-----------" & D_RAMrd(15 downto 11)) and D_sz_msk;
when "1100" => D_srlRAM <= ("------------" & D_RAMrd(15 downto 12)) and D_sz_msk;
when "1101" => D_srlRAM <= ("-------------" & D_RAMrd(15 downto 13)) and D_sz_msk;
when "1110" => D_srlRAM <= ("--------------" & D_RAMrd(15 downto 14)) and D_sz_msk;
when "1111" => D_srlRAM <= ("---------------" & D_RAMrd(15 downto 15)) and D_sz_msk;
when others => null;
end case;
end process shift_data;

--  4 bit RAMwe location adder
D_MSB_msk_adr <= I_imm(3 downto 0) + I_cc;
D_LSB_msk_adr <= I_imm(3 downto 0);

--  condition code flag extraction
CCcfg <= R_cc(1);
CCzfg <= not(R_acc(0)OR R_acc(1)OR R_acc(2)OR R_acc(3)OR
      R_acc(4)OR R_acc(5)OR R_acc(6)OR R_acc(7)OR R_acc(8)OR R_acc(9)OR
      R_acc(10)OR R_acc(11)OR R_acc(12)OR R_acc(13)OR R_acc(14)OR R_acc(15));
CCplfg <= R_acc(15);
CCpofg <= '0';
CCgtfg <='0';
CCa1sfg <= '0';
CCodfg <= R_acc(0);
--CCovfg <= '0';
--CCzfg <= R_cc(0); CCplfg <= R_cc(2); CCpofg <= R_cc(3);
--CCgtfg <= R_cc(4); CCa1sfg <= R_cc(5); CCodfg <= R_cc(6); CCovfg <= R_cc(7);

--    ALU & Write mask generation
msk_gen: process (D_MSB_msk_adr, D_LSB_msk_adr, I_cc) begin
case I_cc is
when "0000" => D_sz_msk <= "0000000000000001";
when "0001" => D_sz_msk <= "0000000000000011";
when "0010" => D_sz_msk <= "0000000000000111";
when "0011" => D_sz_msk <= "0000000000001111";
when "0100" => D_sz_msk <= "0000000000011111";
when "0101" => D_sz_msk <= "0000000000111111";
when "0110" => D_sz_msk <= "0000000001111111";
when "0111" => D_sz_msk <= "0000000011111111";
when "1000" => D_sz_msk <= "0000000111111111";
when "1001" => D_sz_msk <= "0000001111111111";
when "1010" => D_sz_msk <= "0000011111111111";
when "1011" => D_sz_msk <= "0000111111111111";
when "1100" => D_sz_msk <= "0001111111111111";
when "1101" => D_sz_msk <= "0011111111111111";
when "1110" => D_sz_msk <= "0111111111111111";
when "1111" => D_sz_msk <= "1111111111111111";
when others => null;
end case;

case D_MSB_msk_adr is
when "0000" => D_MSB_msk <= "0000000000000001";
when "0001" => D_MSB_msk <= "0000000000000011";
when "0010" => D_MSB_msk <= "0000000000000111";
when "0011" => D_MSB_msk <= "0000000000001111";
when "0100" => D_MSB_msk <= "0000000000011111";
when "0101" => D_MSB_msk <= "0000000000111111";
when "0110" => D_MSB_msk <= "0000000001111111";
when "0111" => D_MSB_msk <= "0000000011111111";
when "1000" => D_MSB_msk <= "0000000111111111";
when "1001" => D_MSB_msk <= "0000001111111111";
when "1010" => D_MSB_msk <= "0000011111111111";
when "1011" => D_MSB_msk <= "0000111111111111";
when "1100" => D_MSB_msk <= "0001111111111111";
when "1101" => D_MSB_msk <= "0011111111111111";
when "1110" => D_MSB_msk <= "0111111111111111";
when "1111" => D_MSB_msk <= "1111111111111111";
when others => null;
end case;

case D_LSB_msk_adr is
when "0000" => D_LSB_msk <= "1111111111111111";
when "0001" => D_LSB_msk <= "1111111111111110";
when "0010" => D_LSB_msk <= "1111111111111100";
when "0011" => D_LSB_msk <= "1111111111111000";
when "0100" => D_LSB_msk <= "1111111111110000";
when "0101" => D_LSB_msk <= "1111111111100000";
when "0110" => D_LSB_msk <= "1111111111000000";
when "0111" => D_LSB_msk <= "1111111110000000";
when "1000" => D_LSB_msk <= "1111111100000000";
when "1001" => D_LSB_msk <= "1111111000000000";
when "1010" => D_LSB_msk <= "1111110000000000";
when "1011" => D_LSB_msk <= "1111100000000000";
when "1100" => D_LSB_msk <= "1111000000000000";
when "1101" => D_LSB_msk <= "1110000000000000";
when "1110" => D_LSB_msk <= "1100000000000000";
when "1111" => D_LSB_msk <= "1000000000000000";
when others => null;
end case;

end process msk_gen;

--    CC processing: determine if instruction is to be performed
cc_test: process
    (I_op,I_cc,CCzfg,CCcfg,CCplfg,CCpofg,CCgtfg,CCa1sfg,CCodfg,CCovfg,cc_do_inst) begin
--    does not include predication testing
case I_cc(3 downto 1) is
when ccZ(3 downto 1) 	=> cc_do_inst <= CCzfg xor I_cc(0);
when ccC(3 downto 1) 	=> cc_do_inst <= CCcfg xor I_cc(0);
when ccPL(3 downto 1) 	=> cc_do_inst <= CCplfg xor I_cc(0);
when ccSKN(3 downto 1)  => cc_do_inst <= not I_cc(0);
when ccPO(3 downto 1) 	=> cc_do_inst <= CCpofg xor I_cc(0);
when ccGT(3 downto 1) 	=> cc_do_inst <= CCgtfg xor I_cc(0);
when ccA1S(3 downto 1)  => cc_do_inst <= CCa1sfg xor I_cc(0);
when ccOD(3 downto 1) 	=> cc_do_inst <= CCodfg xor I_cc(0);
when others => null;
end case;
if (I_op = opALU or I_op = opLUT) then C_cc_do_inst <= '1'; else C_cc_do_inst <= cc_do_inst; end if;
end process cc_test;

-- instruction processing
decode: process(R_TI_state,start,D_RAMrd,R_acc,CCzfg,I_op,R_pc,I_ir,d_srlram,i_imm,aa_nxpc,R_cc,
					d_ext_imm,d_acc17,d_msb_msk,d_lsb_msk,c_cc_do_inst,i_adr,r_rtnstk_adr,r_stkrd) begin
--  default values for update enables & "nx" signals
TI_nxstate <= HLT;
E_pc       <= '0';
E_acc      <= '0';
E_CC		  <= '0';
E_cry      <= '0';
E_cryin    <= '-';
E_rtnstk_adr    <= '0';
E_RAMwe    <= (others => '-');
E_DatRAMwe <= '0';
D_nxacc    <= (others => '0');
D_ensub    <= (others => '-');
D_RAMwtd   <= (others => '-');
A_rtnstk_adr    <= (others => '-');
A_nxpc     <= (others => '-');
AA_nxpc    <= (others => '-');
C_nxcry    <= '-';
C_noskip   <= '1';

--  state dispatch
    case R_TI_state is
    when HLT    =>		-- Halt state, wait for start = '1'
        if start = '1' then TI_nxstate <= RUN; C_noskip <= '0';
                 else TI_nxstate <= HLT; C_noskip <= '1'; end if;
        E_pc     <= '0';    -- no change to PC

    when LUT    =>		-- LUT state, get LUT field from program memory and return
        TI_nxstate <= RUN;
		  E_pc     <= '1';
		  A_nxpc <= R_STKrd(9 downto 0);	-- get PC from return stack
        E_rtnstk_adr <= '1'; A_rtnstk_adr <= R_rtnstk_adr(RDADR_BITS-1 downto 0) - 1;
		  case R_cc(7 downto 4) is		-- dispatch on saved op-code
		  when opLUT1B | opLUT1 => 	-- one bit result
			   case R_acc(3 downto 0) is
			   when "0000" => D_nxacc <= "000000000000000" & I_ir(0);
			   when "0001" => D_nxacc <= "000000000000000" & I_ir(1);
			   when "0010" => D_nxacc <= "000000000000000" & I_ir(2);
			   when "0011" => D_nxacc <= "000000000000000" & I_ir(3);
			   when "0100" => D_nxacc <= "000000000000000" & I_ir(4);
			   when "0101" => D_nxacc <= "000000000000000" & I_ir(5);
			   when "0110" => D_nxacc <= "000000000000000" & I_ir(6);
			   when "0111" => D_nxacc <= "000000000000000" & I_ir(7);
			   when "1000" => D_nxacc <= "000000000000000" & I_ir(8);
			   when "1001" => D_nxacc <= "000000000000000" & I_ir(9);
			   when "1010" => D_nxacc <= "000000000000000" & I_ir(10);
			   when "1011" => D_nxacc <= "000000000000000" & I_ir(11);
			   when "1100" => D_nxacc <= "000000000000000" & I_ir(12);
			   when "1101" => D_nxacc <= "000000000000000" & I_ir(13);
			   when "1110" => D_nxacc <= "000000000000000" & I_ir(14);
			   when "1111" => D_nxacc <= "000000000000000" & I_ir(15);
				when others => null;
				end case;
		  when opLUT2B | opLUT2 => 	-- two bit result
			   case R_acc(2 downto 0) is
			   when "000" => D_nxacc <= "00000000000000" & I_ir(1 downto 0);
			   when "001" => D_nxacc <= "00000000000000" & I_ir(3 downto 2);
			   when "010" => D_nxacc <= "00000000000000" & I_ir(5 downto 4);
			   when "011" => D_nxacc <= "00000000000000" & I_ir(7 downto 6);
			   when "100" => D_nxacc <= "00000000000000" & I_ir(9 downto 8);
			   when "101" => D_nxacc <= "00000000000000" & I_ir(11 downto 10);
			   when "110" => D_nxacc <= "00000000000000" & I_ir(13 downto 12);
			   when "111" => D_nxacc <= "00000000000000" & I_ir(15 downto 14);
				when others => null;
				end case;
		  when opLUT4B | opLUT4 => 	-- four bit result
			   case R_acc(1 downto 0) is
			   when "00" => D_nxacc <= "000000000000" & I_ir(3 downto 0);
			   when "01" => D_nxacc <= "000000000000" & I_ir(7 downto 4);
			   when "10" => D_nxacc <= "000000000000" & I_ir(11 downto 8);
			   when "11" => D_nxacc <= "000000000000" & I_ir(15 downto 12);
				when others => null;
				end case;
		  when opLUT8B | opLUT8 => 	-- eight bit result
			   case R_acc(0) is
			   when '0' => D_nxacc <= "00000000" & I_ir(7 downto 0);
			   when '1' => D_nxacc <= "00000000" & I_ir(15 downto 8);
				when others => null;
				end case;
		  when opLUT16 => D_nxacc <= I_ir(15 downto 0); 	-- 16 bit result
		  when others => null;
		  end case;

    when RUN    =>
--  op-code dispatch
case I_op is                     -- instruction processing
when opLD  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= D_srlRAM;

when opLDC =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= not D_srlRAM;

when opLDI | opLDIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= D_ext_imm;

when opAND =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    D_nxacc  <= R_acc and D_srlRAM;

when opANDI | opANDIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= R_acc and D_ext_imm;

when opOR  =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    D_nxacc  <= R_acc or D_srlRAM;

when opORI | opORIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= R_acc or D_ext_imm;

when opXOR =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    D_nxacc  <= R_acc xor D_srlRAM;

when opXORI | opXORIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= R_acc xor D_ext_imm;

when opADD =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    D_ensub  <= (others => '0');
    D_nxacc  <= D_acc17(15 downto 0);
    E_cry    <= '1'; C_nxcry <= D_acc17(16);

when opADDI | opADDIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= R_acc + D_ext_imm;

when opADC =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    E_cryin  <= '1';
    D_ensub  <= (others => '0');
    D_nxacc  <= D_acc17(15 downto 0);
    E_cry    <= '1'; C_nxcry <= D_acc17(16);

when opSUB =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '1';
    D_ensub  <= (others => '1');
    D_nxacc  <= D_acc17(15 downto 0);
    E_cry    <= '1'; C_nxcry <= D_acc17(16);

when opSUBI | opSUBIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '1';
    D_nxacc   <= R_acc - D_ext_imm;

when opSBC =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc <= R_pc + 1;
    E_acc    <= '1';
    E_cryin  <= '1';
    D_ensub  <= (others => '1');
    D_nxacc  <= D_acc17(15 downto 0);
    E_cry    <= '1'; C_nxcry <= D_acc17(16);

when opBIT =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '0';
    D_nxacc  <= R_acc and D_srlRAM;

when opBITI | opBITIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '0';
    D_nxacc   <= R_acc and D_ext_imm;

when opCMP =>
    TI_nxstate <= RUN;
    E_pc     <= '1'; A_nxpc    <= R_pc + 1;
    E_acc    <= '0';
    D_ensub  <= (others => '1');
    D_nxacc  <= D_acc17(15 downto 0);
    E_cry    <= '1'; C_nxcry <= D_acc17(16);

when opCMPI | opCMPIU =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc    <= R_pc + 1;
    E_acc     <= '0';
    D_nxacc   <= R_acc - D_ext_imm;

when opST  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc <= R_pc + 1;
	 E_DatRAMwe <= '1';
    E_RAMwe   <= D_MSB_msk and D_LSB_msk;
	 case I_imm(3 downto 0) is
	 when "0000" => D_RAMwtd  <= R_acc;
	 when "0001" => D_RAMwtd  <= R_acc(14 downto 0) & '-';
	 when "0010" => D_RAMwtd  <= R_acc(13 downto 0) & "--";
	 when "0011" => D_RAMwtd  <= R_acc(12 downto 0) & "---";
	 when "0100" => D_RAMwtd  <= R_acc(11 downto 0) & "----";
	 when "0101" => D_RAMwtd  <= R_acc(10 downto 0) & "-----";
	 when "0110" => D_RAMwtd  <= R_acc(9 downto 0)  & "------";
	 when "0111" => D_RAMwtd  <= R_acc(8 downto 0)  & "-------";
	 when "1000" => D_RAMwtd  <= R_acc(7 downto 0)  & "--------";
	 when "1001" => D_RAMwtd  <= R_acc(6 downto 0)  & "---------";
	 when "1010" => D_RAMwtd  <= R_acc(5 downto 0)  & "----------";
	 when "1011" => D_RAMwtd  <= R_acc(4 downto 0)  & "-----------";
	 when "1100" => D_RAMwtd  <= R_acc(3 downto 0)  & "------------";
	 when "1101" => D_RAMwtd  <= R_acc(2 downto 0)  & "-------------";
	 when "1110" => D_RAMwtd  <= R_acc(1 downto 0)  & "--------------";
	 when "1111" => D_RAMwtd  <= R_acc(0 downto 0)  & "---------------";
    when others => null;
    end case;

when opCLR  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc <= R_pc + 1;
	 E_DatRAMwe <= '1';
    E_RAMwe   <= D_MSB_msk and D_LSB_msk;
    D_RAMwtd  <= (others => '0');

when opSET  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc <= R_pc + 1;
	 E_DatRAMwe <= '1';
    E_RAMwe   <= D_MSB_msk and D_LSB_msk;
    D_RAMwtd  <= (others => '1');

when opINC  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc <= R_pc + 1;
	 E_DatRAMwe <= '1';
    E_RAMwe   <= D_MSB_msk and D_LSB_msk;
    D_RAMwtd  <= D_RAMrd + (not D_LSB_msk) + "0000000000000001";

when opDEC  =>
    TI_nxstate <= RUN;
    E_pc      <= '1'; A_nxpc <= R_pc + 1;
	 E_DatRAMwe <= '1';
    E_RAMwe   <= D_MSB_msk and D_LSB_msk;
    D_RAMwtd  <= D_RAMrd + D_LSB_msk;

when opJMP00 | opJMP01 | opJMP10 | opJMP11 =>
    TI_nxstate <= RUN;
    E_pc       <= '1';
    if C_cc_do_inst = '1' then A_nxpc <= I_adr;
                    else A_nxpc <= R_pc + 1; end if;

when opCALL00 | opCALL01 | opCALL10 | opCALL11 =>
    TI_nxstate <= RUN;
    E_pc       <= '1';
    if C_cc_do_inst = '1'
    then A_nxpc <= I_adr;
         E_rtnstk_adr <= '1'; A_rtnstk_adr <= R_rtnstk_adr(RDADR_BITS-1 downto 0) + 1;
    else A_nxpc <= R_pc + 1; end if;

when opLUT00 | opLUT01 | opLUT10 | opLUT11 =>	-- push PC+1 onto return stack, change to LUT state
	-- new PC is LUT table plus offset to LUT word
	-- 
	TI_nxstate <= LUT;
	E_pc <= '1'; 
	E_CC <= '1'; 
   E_rtnstk_adr <= '1'; A_rtnstk_adr <= R_rtnstk_adr(RDADR_BITS-1 downto 0) + 1;
	if R_acc(0) = '1' then 
		case R_cc(6 downto 4) is 
		when opLUT1(2 downto 0) => AA_nxpc <= I_adr(9 downto 1) & R_acc(4);
		when opLUT2(2 downto 0) => AA_nxpc <= I_adr(9 downto 1) & R_acc(3);
		when opLUT4(2 downto 0) => AA_nxpc <= I_adr(9 downto 1) & R_acc(2);
		when opLUT8(2 downto 0) => AA_nxpc <= I_adr(9 downto 1) & R_acc(1);
		when opLUT16(2 downto 0) => AA_nxpc <= I_adr(9 downto 1) & R_acc(0);
		when others  => null;
		end case;
	elsif R_acc(1) = '1' then
		case R_cc(6 downto 4) is 
		when opLUT1(2 downto 0) => AA_nxpc <= I_adr(9 downto 2) & R_acc(5 downto 4);
		when opLUT2(2 downto 0) => AA_nxpc <= I_adr(9 downto 2) & R_acc(4 downto 3);
		when opLUT4(2 downto 0) => AA_nxpc <= I_adr(9 downto 2) & R_acc(3 downto 2);
		when opLUT8(2 downto 0) => AA_nxpc <= I_adr(9 downto 2) & R_acc(2 downto 1);
		when opLUT16(2 downto 0) => AA_nxpc <= I_adr(9 downto 2) & R_acc(1 downto 0);
		when others  => null;
		end case;
	elsif R_acc(2) = '1' then
		case R_cc(6 downto 4) is 
		when opLUT1(2 downto 0) => AA_nxpc <= I_adr(9 downto 3) & R_acc(6 downto 4);
		when opLUT2(2 downto 0) => AA_nxpc <= I_adr(9 downto 3) & R_acc(5 downto 3);
		when opLUT4(2 downto 0) => AA_nxpc <= I_adr(9 downto 3) & R_acc(4 downto 2);
		when opLUT8(2 downto 0) => AA_nxpc <= I_adr(9 downto 3) & R_acc(3 downto 1);
		when opLUT16(2 downto 0) => AA_nxpc <= I_adr(9 downto 3) & R_acc(2 downto 0);
		when others  => null;
		end case;
	else
		case R_cc(6 downto 4) is 
		when opLUT1(2 downto 0) => AA_nxpc <= I_adr(9 downto 4) & R_acc(7 downto 4);
		when opLUT2(2 downto 0) => AA_nxpc <= I_adr(9 downto 4) & R_acc(6 downto 3);
		when opLUT4(2 downto 0) => AA_nxpc <= I_adr(9 downto 4) & R_acc(5 downto 2);
		when opLUT8(2 downto 0) => AA_nxpc <= I_adr(9 downto 4) & R_acc(4 downto 1);
		when opLUT16(2 downto 0) => AA_nxpc <= I_adr(9 downto 4) & R_acc(3 downto 0);
		when others  => null;
		end case;
	end if;
	
	case R_cc(7 downto 4) is			-- save LUT table location into PC
	when opLUT1 | opLUT2 | opLUT4 | opLUT8 | opLUT16  => A_nxpc <= AA_nxpc;
	when opLUT1B => A_nxpc <= I_adr;	-- single LUT word
	when opLUT2B => A_nxpc <= I_adr;	-- single LUT word
	when opLUT4B => A_nxpc <= I_adr;	-- single LUT word
	when opLUT8B => A_nxpc <= I_adr;	-- single LUT word
	when others  => null;
	end case;

when opLUT1I => -- use three LSBs of ACC to select one of eight bits in immediate field
	TI_nxstate <= RUN;
	E_pc       <= '1'; A_nxpc <= R_pc + 1;
	E_acc      <= '1';
	case R_acc(2 downto 0) is
	when "000" => D_nxacc   <= "000000000000000" & I_imm(0);
	when "001" => D_nxacc   <= "000000000000000" & I_imm(1);
	when "010" => D_nxacc   <= "000000000000000" & I_imm(2);
	when "011" => D_nxacc   <= "000000000000000" & I_imm(3);
	when "100" => D_nxacc   <= "000000000000000" & I_imm(4);
	when "101" => D_nxacc   <= "000000000000000" & I_imm(5);
	when "110" => D_nxacc   <= "000000000000000" & I_imm(6);
	when "111" => D_nxacc   <= "000000000000000" & I_imm(7);
	when others => null;
	end case;

when opLUT2I => -- use two LSBs of ACC to select one pair from eight bits in immediate field 
	TI_nxstate <= RUN;
	E_pc       <= '1'; A_nxpc <= R_pc + 1;
	E_acc      <= '1';
	case R_acc(1 downto 0) is
	when "00" => D_nxacc    <= "00000000000000" & I_imm(1 downto 0);
	when "01" => D_nxacc    <= "00000000000000" & I_imm(3 downto 2);
	when "10" => D_nxacc    <= "00000000000000" & I_imm(5 downto 4);
	when "11" => D_nxacc    <= "00000000000000" & I_imm(7 downto 6);
	when others => null;
	end case;

when opLUT4I => -- use LSB of ACC to select one nibble from eight bits in immediate field
	TI_nxstate <= RUN;
	E_pc       <= '1'; A_nxpc <= R_pc + 1;
	E_acc      <= '1';
	case R_acc(0) is
	when '0' => D_nxacc     <= "000000000000" & I_imm(3 downto 0);
	when '1' => D_nxacc     <= "000000000000" & I_imm(7 downto 4);
	when others => null;
	end case;
when opPRED => null;
		
when opRTNcc =>
    TI_nxstate <= RUN;
    E_pc       <= '1';
    if C_cc_do_inst = '1'
    then A_nxpc <= R_STKrd(9 downto 0);
         E_rtnstk_adr <= '1'; A_rtnstk_adr <= R_rtnstk_adr(RDADR_BITS-1 downto 0) - 1;
    else A_nxpc <= R_pc + 1; end if;

when others => null;
end case;
    when others => null;
    end case;
end process decode;

--      all processor register updates
update: process(clk,rst) begin
if (rst='1') then       -- syncronous reset
		 R_pc      <= (others => '0');
                 -- register updates
elsif rising_edge(clk) then
	--                  inst adr update
	--      pipeline the instruction memory output
	--    ir <= irr;
	--      Program counter update
		 if E_pc = '1'    then R_pc <= A_nxpc; end if;
end if;
end process update;

update2: process(clk,rst) begin
if (rst='1')        -- syncronous reset
	then                  -- reset values:
		 R_TI_state <= HLT;
		 R_acc     <= (others => '0');
		 R_cc      <= (others => '0');
		 R_rtnstk_adr <= (others => '0');
elsif rising_edge(clk) then
		 R_TI_state <= TI_nxstate;
	--                  Other register updates
	if C_noskip = '1'  -- register updates
		then
		--      state variable update
			 if halt_sig = '0' then R_TI_state <= TI_nxstate; else R_TI_state <= HLT; end if;
		--      accumulator update
			 if E_acc = '1'   then R_acc    <= D_nxacc; end if;
		--      update carry bit
			 if E_cry = '1'   then R_cc(1)  <= C_nxcry; end if;
		--      save CC instruction bits for LUT operation
			 if E_CC = '1'   then R_cc(7 downto 4)  <= I_cc; end if;
		--      return & accumlator stack
			 if E_rtnstk_adr = '1' then R_rtnstk_adr <= A_rtnstk_adr; end if;
	end if;
end if;
end process update2;

end behav;





















































































