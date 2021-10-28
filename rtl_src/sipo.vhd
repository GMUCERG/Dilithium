-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- serial input parallel output

entity sipo is
	generic ( 
		N	: integer := 512;
		M	: integer := 32		-- N must be divisible by M
	);
	port (
		clk 	 : in std_logic;				 
		en     : in std_logic;
		input  : in std_logic_vector(M-1 downto 0);
		output : out std_logic_vector(N-1 downto 0)
	);
end sipo;

architecture Behavioral of sipo is
	constant regamount : integer := N/M;
	type reg_array is array ( 0 to regamount-1 ) of std_logic_vector(M-1 downto 0);
	signal reg : reg_array;	
begin
	output_gen : for i in regamount-1 downto 0 generate
		output((M*i + (M-1)) downto M*i ) <= reg(regamount-i-1);
	end generate;
	
	regX_gen : for i in regamount-2 downto 0 generate
		regX : process ( clk )
		begin
			if rising_edge(clk) then	 
				if ( en = '1' ) then
					reg(i) <= reg(i+1);	
				end if;
			end if;
		end process;
	end generate;
	
	regLast : process ( clk )
	begin
		if rising_edge(clk) then   
			if ( en = '1' ) then
				reg(regamount-1) <= input;
			end if;
		end if;
	end process;
		
end Behavioral;

