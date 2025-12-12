--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:41:27 01/07/2017
-- Design Name:   
-- Module Name:   C:/_jcb_uP/_github/LEM1_9/LEM1_9_S6-3/LEM1_9tb.vhd
-- Project Name:  LEM1_9_S6-3
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: LEM1_9
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
USE work.constants.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY LEM1_9tb IS
END LEM1_9tb;
 
ARCHITECTURE behavior OF LEM1_9tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT LEM1_9
    PORT(
         CLOCK_Y3   : IN  std_logic;
         PC_tb          : OUT  std_logic_vector(prog_adr_size-1 downto 0);
         inst_tb        : out  std_logic_vector(inst_size-1 downto 0);
         rstack_ptr_tb  : OUT  std_logic_vector(rtn_ptr_size-1 downto 0);
         A_tb           : OUT  std_logic;
         C_tb           : OUT  std_logic;
         bitRAM_we_tb   : out  std_logic;
         bitRAMw_DI_tb  : out  std_logic;
         bitRAMw_DO_tb  : out  std_logic;
         GPIO_DIP1 : IN  std_logic;
         GPIO_DIP2 : IN  std_logic;
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

 	--Outputs
   signal PC_tb          : std_logic_vector(prog_adr_size-1 downto 0);
   signal inst_tb        : std_logic_vector(inst_size-1 downto 0);
   signal rstack_ptr_tb  : std_logic_vector(rtn_ptr_size-1 downto 0);
   signal A_tb           : std_logic;
   signal C_tb           : std_logic;
   signal bitRAM_we_tb   : std_logic;
   signal bitRAMw_DI_tb  : std_logic;
   signal bitRAMw_DO_tb  : std_logic;
   signal GPIO_LED1 : std_logic;
   signal GPIO_LED2 : std_logic;
   signal GPIO_LED3 : std_logic;
   signal GPIO_LED4 : std_logic;

   -- Clock period definitions
   constant CLOCK_Y3_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: LEM1_9 PORT MAP (
          CLOCK_Y3 => CLOCK_Y3,
     PC_tb          => PC_tb,
     inst_tb        => inst_tb,
     rstack_ptr_tb  => rstack_ptr_tb,
     A_tb           => A_tb,
     C_tb           => C_tb,
     bitRAM_we_tb   => bitRAM_we_tb,
     bitRAMw_DI_tb  => bitRAMw_DI_tb,
     bitRAMw_DO_tb  => bitRAMw_DO_tb,
          GPIO_DIP1 => GPIO_DIP1,
          GPIO_DIP2 => GPIO_DIP2,
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
