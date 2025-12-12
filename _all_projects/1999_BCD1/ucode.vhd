--	ucode.vhd	instruction decode
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package ucode is
  type uct_a is (clr,ldimm,lde,inc);  -- 4 types
  type uct_b is (clr,ldimm,lde,inc);  -- 4 types
  type uct_c is (clr,ldpc,ldimm,lde,inc);  -- 5 types
  type uct_l is (clr,ldimm,lde,dec);  -- 4 types
  type uct_pc is (clr,ldimm,lde,inc);  -- 4 types
  type uct_im is (clr,ldpc,ldc); -- 3 types
  type uct_s is (alu,ldd,lde,clr,a0,a1,a2,b0,b1,b2,c0,c1,c2,l0,l1,l2,pc0,pc1,pc2,im0,im1,im2); -- 22 types

  -- ucode is approxmately 26 bits wide.

  component uc_rom
    port (
    	op:in std_logic_vector (7 downto 0);
    	st: state;
    	uc_a:	out uct_a;
    	uc_b: out uct_b;
    	uc_c: out uct_c;
    	uc_l: out uct_l;
    	uc_pc: out uct_pc;
    	uc_s: out uct_s
         );
  end component;

  component a_rom port  (op: in std_logic_vector (7 downto 0); uc_a:out uct_a); end component;
  component b_rom port  (op: in std_logic_vector (7 downto 0); uc_b:out uct_b); end component;
  component c_rom port  (op: in std_logic_vector (7 downto 0); uc_c:out uct_c); end component;
  component l_rom port  (op: in std_logic_vector (7 downto 0); uc_l:out uct_l); end component;
  component pc_rom port (op: in std_logic_vector (7 downto 0); uc_pc:out uct_pc); end component;
  component s_rom port  (st: in state; uc_s: out uct_s); end component;

end ucode;

package body ucode is
end ucode;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.ucode.all;

entity a_rom is
    port (op:   in std_logic_vector (7 downto 0);
          uc_a: out uct_a
         );
end ucta_rom;


architecture a_rom_arch of a_rom is
begin
  process (op)
  begin
    case op is
        when "10100000" => uc_a <=
        when others =>    ;
    end case;
  end process;
end a_rom_arch;


--BCD Opcode Summary
--  
--op_code,flags, neumonic: definition
--A0(ZCN)W3 ADDI		add imm
--A1(ZCN)W3 ADD:		add
--A2(ZCN)W3 ADDIE:	add imm & extend
--A3(ZCN)W3 ADDE:		add & extend
--A4(ZCN)W3 SUBI:		sub imm
--A5(ZCN)W3 SUB:		subtract
--A6(ZCN)W3 SUBIE:	sub imm & extend
--A7(ZCN)W3 SUBE:		sub & extend
--A8		 I LDA:		load A abs
--A9		WI STA:		store A abs
--B0		W2 MOVI:		move imm
--B1		W2 MOV:		move
--B2		W3 MOVIE:	move imm & expand per B
--B3		W3 MOVE:		move & expand per B
--B4		W2 MOVRI:	move record imm
--B5		W2 MOVR:		move record
--B6		W3 MOVRIE:	move record imm & expand per B
--B7		W3 MOVRE:	move recore & expand per B
--B8		 I LDB:		load B abs
--B9		WI STB:		store B abs
--C0		 I BC:		branch carry
--C1		 I BNC:		branch no carry
--C2		 I BZ:		branch zero
--C3		 I BNZ:		branch non-zero
--C4		 I BN:		branch negative
--C5		 I BNN:		branch not negative
--C6		 I BGTZ:		branch greater than zero
--C7		 I BNGTZ:	branch less than or equal zero
--C8		 I LDC:		load C abs
--C9		WI STC:		store C abs
--D0		 I LDAI:		load A imm
--D1		 I LDBI:		load B imm
--D2		 I LDCI:		load C imm
--D3		 I LDLI:		load L imm
--D4		 I LDPCI, BRA: load PC imm (branch abs)
--D5(ZN)	 1 TST:		test
--D6(ZN)	 2 CMPI:		compare imm
--D7(ZN)	 2 CMP:		compare
--D8		 I LDL:		load L abs
--D9		WI STL:		store L abs
--E0		:
--E1		:
--E2		:
--E3		:
--E4		:
--E5		:
--E6		:
--E7		:
--E8		 I LDPC, BRI: load PC abs (branch indirect)
--E9		WI STPC:		store PC abs
--F0		:
--F1		:
--F2		:
--F3		:
--F4		:
--F5		:
--F6		:
--F7		:
--F8		 I CALL:		call abs
--F9(Z)	 I SOB:		subtract one & branch abs
