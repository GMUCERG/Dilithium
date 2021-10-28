-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- parallel input serial output 

entity piso is
	generic ( 
		N	: integer := 128;	--inputs
		M	: integer := 32		--outputs -- N must be divisible by M
	);
	port (
		clk 	 : in std_logic;
		en   : in std_logic;
		sel	 : in std_logic;
		input  : in std_logic_vector(N-1 downto 0);		
		output : out std_logic_vector(M-1 downto 0)
	);
end piso;

architecture Behavioral of piso is
	constant regamount : integer := N/M;
	type reg_array is array ( 0 to regamount-1 ) of std_logic_vector(M-1 downto 0);
	signal reg, mux : reg_array;	
begin

	mux(regamount-1) <= input(M-1 downto 0);
	mux_gen : for i in 0 to regamount-2 generate
		mux(i) <= input(N-M*i-1 downto N-M*i-M) when sel = '1' else reg(i+1);
	end generate;
	
	regX_gen : for i in 0 to regamount-1 generate
		regX : process ( clk )
		begin
			if rising_edge(clk) then   
				if ( en = '1' ) then
					reg(i) <= mux(i);
				end if;
			end if;
		end process;
	end generate;
	
	output <= reg(0);
end Behavioral;

