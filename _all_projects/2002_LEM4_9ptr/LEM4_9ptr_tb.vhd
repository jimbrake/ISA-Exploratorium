--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:00:54 01/10/2017
-- Design Name:   
-- Module Name:   C:/_jcb_uP/_github/LEM4_9ptr/LEM4_9ptr_s6-3/LEM4_9ptr_tb.vhd
-- Project Name:  LEM4_9ptr_s6-3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: LEM4_9ptr
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
 
ENTITY LEM4_9ptr_tb IS
END LEM4_9ptr_tb;
 
ARCHITECTURE behavior OF LEM4_9ptr_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT LEM4_9ptr
    PORT(
         CLOCK_Y3 : IN  std_logic;
         PC_tb : OUT  std_logic_vector(7 downto 0);
         inst_tb : OUT  std_logic_vector(8 downto 0);
         rstack_ptr_tb : OUT  std_logic_vector(2 downto 0);
         Acc_tb : OUT  std_logic_vector(3 downto 0);
         Cry_tb : OUT  std_logic;
         bin_bcd_tb : OUT  std_logic;
         digitRAM_we_tb : OUT  std_logic;
         digitRAM_adr_tb : OUT  std_logic_vector(5 downto 0);
         digitRAM_DI_tb : OUT  std_logic_vector(3 downto 0);
         digitRAM_DO_tb : OUT  std_logic_vector(3 downto 0);
         GPIO_DIP1 : IN  std_logic;
         GPIO_DIP2 : IN  std_logic;
         GPIO_DIP3 : IN  std_logic;
         GPIO_DIP4 : IN  std_logic;
         GPIO_LED1 : OUT  std_logic;
         GPIO_LED2 : OUT  std_logic;
         GPIO_LED3 : OUT  std_logic;
         GPIO_LED4 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLOCK_Y3 : std_logic := '0';
   signal GPIO_DIP1 : std_logic := '0';
   signal GPIO_DIP2 : std_logic := '0';
   signal GPIO_DIP3 : std_logic := '0';
   signal GPIO_DIP4 : std_logic := '0';

 	--Outputs
   signal PC_tb : std_logic_vector(7 downto 0);
   signal inst_tb : std_logic_vector(8 downto 0);
   signal rstack_ptr_tb : std_logic_vector(2 downto 0);
   signal Acc_tb : std_logic_vector(3 downto 0);
   signal Cry_tb : std_logic;
   signal bin_bcd_tb : std_logic;
   signal digitRAM_we_tb : std_logic;
   signal digitRAM_adr_tb : std_logic_vector(5 downto 0);
   signal digitRAM_DI_tb : std_logic_vector(3 downto 0);
   signal digitRAM_DO_tb : std_logic_vector(3 downto 0);
   signal GPIO_LED1 : std_logic;
   signal GPIO_LED2 : std_logic;
   signal GPIO_LED3 : std_logic;
   signal GPIO_LED4 : std_logic;

   -- Clock period definitions
   constant CLOCK_Y3_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: LEM4_9ptr PORT MAP (
          CLOCK_Y3 => CLOCK_Y3,
          PC_tb => PC_tb,
          inst_tb => inst_tb,
          rstack_ptr_tb => rstack_ptr_tb,
          Acc_tb => Acc_tb,
          Cry_tb => Cry_tb,
          bin_bcd_tb => bin_bcd_tb,
          digitRAM_we_tb => digitRAM_we_tb,
          digitRAM_adr_tb => digitRAM_adr_tb,
          digitRAM_DI_tb => digitRAM_DI_tb,
          digitRAM_DO_tb => digitRAM_DO_tb,
          GPIO_DIP1 => GPIO_DIP1,
          GPIO_DIP2 => GPIO_DIP2,
          GPIO_DIP3 => GPIO_DIP3,
          GPIO_DIP4 => GPIO_DIP4,
          GPIO_LED1 => GPIO_LED1,
          GPIO_LED2 => GPIO_LED2,
          GPIO_LED3 => GPIO_LED3,
          GPIO_LED4 => GPIO_LED4
        );

   -- Clock process definitions
   CLOCK_Y3_process :process
   begin
		CLOCK_Y3 <= '0';
		wait for CLOCK_Y3_period/2;
		CLOCK_Y3 <= '1';
		wait for CLOCK_Y3_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 1 ns;	

      wait for CLOCK_Y3_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
