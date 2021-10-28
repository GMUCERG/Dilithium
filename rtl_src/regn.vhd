-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all; 

-- n-bits register 

entity regn is
	generic ( 
		N : integer := 32;
		init : std_logic_vector
	);
	port ( 	  
	    clk 	: in std_logic;
		rst 	: in std_logic;
	    en 		: in std_logic; 
		input  	: in std_logic_vector(N-1 downto 0);
        output 	: out std_logic_vector(N-1 downto 0)
	);
end regn;

architecture struct of regn is
--signal reg : std_logic_vector(N-1 downto 0);
begin	
	gen : process( clk )
	begin
		if rising_edge( clk ) then
			if ( rst = '1' ) then
				output <= init;
			elsif ( en = '1' ) then
				output<= input;
			end if;
		end if;
	end process;
	--output <= reg;  
end struct;