--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:46:13 10/11/2015
-- Design Name:   
-- Module Name:   C:/_jcb_uP/the12X_12uP/amd_hexcore/the12X_12uP/the12X_12uP_s6-2/the12X_12up_tb.vhd
-- Project Name:  the12X_12uP_s6-2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: the12x_12up
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
 
ENTITY the12X_12up_tb IS
END the12X_12up_tb;
 
ARCHITECTURE behavior OF the12X_12up_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT the12x_12up
    PORT(
         CLOCK_Y3 : IN  std_logic;
         pc_tb : OUT  std_logic_vector(11 downto 0);
         Q_tb : OUT  std_logic_vector(11 downto 0);
         RSLT_tb : OUT  std_logic_vector(11 downto 0);
         sp_tb : OUT  std_logic_vector(5 downto 0);
         op_tb : OUT  std_logic_vector(5 downto 0);
         dp_tb : OUT  std_logic_vector(5 downto 0);
         CCRZ_tb : OUT  std_logic;
         CCRwe_tb : OUT  std_logic;
         LUTwe_tb : OUT  std_logic;
         outwe_tb : OUT  std_logic;
         USER_RESET : IN  std_logic;
         GPIO_DIP4 : IN  std_logic;
         GPIO_DIP3 : IN  std_logic;
         GPIO_DIP2 : IN  std_logic;
         GPIO_DIP1 : IN  std_logic;
         GPIO_LED1 : OUT  std_logic;
         GPIO_LED2 : OUT  std_logic;
         GPIO_LED3 : OUT  std_logic;
         GPIO_LED4 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLOCK_Y3 : std_logic := '0';
   signal USER_RESET : std_logic := '0';
   signal GPIO_DIP4 : std_logic := '0';
   signal GPIO_DIP3 : std_logic := '0';
   signal GPIO_DIP2 : std_logic := '0';
   signal GPIO_DIP1 : std_logic := '0';

 	--Outputs
   signal pc_tb : std_logic_vector(11 downto 0);
   signal Q_tb : std_logic_vector(11 downto 0);
   signal RSLT_tb : std_logic_vector(11 downto 0);
   signal sp_tb : std_logic_vector(5 downto 0);
   signal op_tb : std_logic_vector(5 downto 0);
   signal dp_tb : std_logic_vector(5 downto 0);
   signal CCRZ_tb : std_logic;
   signal CCRwe_tb : std_logic;
   signal LUTwe_tb : std_logic;
   signal outwe_tb : std_logic;
   signal GPIO_LED1 : std_logic;
   signal GPIO_LED2 : std_logic;
   signal GPIO_LED3 : std_logic;
   signal GPIO_LED4 : std_logic;

   -- Clock period definitions
   constant CLOCK_Y3_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: the12x_12up PORT MAP (
          CLOCK_Y3 => CLOCK_Y3,
          pc_tb => pc_tb,
          Q_tb => Q_tb,
          RSLT_tb => RSLT_tb,
          sp_tb => sp_tb,
          op_tb => op_tb,
          dp_tb => dp_tb,
          CCRZ_tb => CCRZ_tb,
          CCRwe_tb => CCRwe_tb,
          LUTwe_tb => LUTwe_tb,
          outwe_tb => outwe_tb,
          USER_RESET => USER_RESET,
          GPIO_DIP4 => GPIO_DIP4,
          GPIO_DIP3 => GPIO_DIP3,
          GPIO_DIP2 => GPIO_DIP2,
          GPIO_DIP1 => GPIO_DIP1,
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
--      -- hold reset state for 100 ns.
--      wait for 100 ns;	
--
      wait for CLOCK_Y3_period*8202;

      -- insert stimulus here 
USER_RESET<='1';
--      wait;
   end process;

END;
