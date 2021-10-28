-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.sha3_pkg.all;

-- up counter
-- possible values for generic style = {COUNTER_STYLE_1, COUNTER_STYLE_2, COUNTER_STYLE_3}

entity countern is
	generic ( 
		N 	: integer := 2;
		step	:integer  :=1;
		style	:integer :=COUNTER_STYLE_1		
	);
	port ( 	  
		clk : in std_logic;
		rst : in std_logic;
	    load : in std_logic;
	    en : in std_logic; 
		input  : in std_logic_vector(N-1 downto 0);
        output : out std_logic_vector(N-1 downto 0)
	);
end countern;

architecture countern of countern is
   signal temp 		: std_logic_vector(N-1 downto 0);
   signal value 	: std_logic_vector(N-1 downto 0);
   signal init_value 	: std_logic_vector(N-1 downto 0);

begin
	
	s1: if style = COUNTER_STYLE_1 generate
		value <= std_logic_vector(to_unsigned(step, N));
		init_value <= input;
	end generate;

	s2: if style = COUNTER_STYLE_2 generate
		value <= input;
		init_value <= (others => '0');
	end generate;

	s3: if style = COUNTER_STYLE_3 generate
		value <= input;
		init_value <= input;
	end generate;

	
	gen : process( clk )
	begin
		if rising_edge( clk ) then
			if ( rst = '1' ) then
				temp <= init_value;
			elsif (load = '1' ) then
				temp <= input;
			elsif ( en = '1' ) then
				temp <= temp + value;
			end if;
		end if;
	end process;  
	output <= temp;
end countern;

