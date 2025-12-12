--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:06:18 02/10/2016
-- Design Name:   
-- Module Name:   C:/_jcb_uP/rois24_24uP/rois24_24up_s6_noram/rois24_24up_s6_noram_tb.vhd
-- Project Name:  rois24_24up_s6_noram
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: rois24_24up
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY rois24_24up_s6_noram_tb IS
END rois24_24up_s6_noram_tb;
 
ARCHITECTURE behavior OF rois24_24up_s6_noram_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT rois24_24up
    PORT(
         CLOCK_Y3  : IN  std_logic;
         PC_tb     : OUT  std_logic_vector(9 downto 0);
         inst_tb   : out std_logic_vector(23 downto 0);
         dloc_tb   : OUT  std_logic_vector(5 downto 0);
         dlocwe_tb : OUT  std_logic;
         CCRN_tb   : OUT  std_logic_vector(26 downto 0);
         GPIO_LED1 : OUT  std_logic;
         GPIO_LED2 : OUT  std_logic;
         GPIO_LED3 : OUT  std_logic;
         GPIO_LED4 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLOCK_Y3 : std_logic := '0';

 	--Outputs
   signal PC_tb     : std_logic_vector(9 downto 0);
   signal inst_tb   : std_logic_vector(23 downto 0);
   signal dloc_tb   : std_logic_vector(5 downto 0);
   signal dlocwe_tb : std_logic;
   signal CCRN_tb   : std_logic_vector(26 downto 0);
   signal GPIO_LED1 : std_logic;
   signal GPIO_LED2 : std_logic;
   signal GPIO_LED3 : std_logic;
   signal GPIO_LED4 : std_logic;

   -- Clock period definitions
   constant CLOCK_Y3_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: rois24_24up PORT MAP (
          CLOCK_Y3  => CLOCK_Y3,
          PC_tb     => PC_tb,
          inst_tb   => inst_tb,
          dloc_tb   => dloc_tb,
          dlocwe_tb => dlocwe_tb,
          CCRN_tb   => CCRN_tb,
          GPIO_LED1 => GPIO_LED1,
          GPIO_LED2 => GPIO_LED2,
          GPIO_LED3 => GPIO_LED3,
          GPIO_LED4 => GPIO_LED4
        );

   -- Clock process definitions
   CLOCK_Y3_process :process
   begin
		CLOCK_Y3 <= '1';
		wait for CLOCK_Y3_period/2;
		CLOCK_Y3 <= '0';
		wait for CLOCK_Y3_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLOCK_Y3_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
