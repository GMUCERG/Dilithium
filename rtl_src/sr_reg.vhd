-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;

entity sr_reg is
	generic (
	  	init : std_logic := '0'
	);
	port (
		rst			: in std_logic;
		clk 		: in std_logic;
		set     	: in std_logic;
		clr         : in std_logic;
		output		: out std_logic
	);
end sr_reg;

architecture struct of sr_reg is
	signal output_s : std_logic;
begin
	reg_gen : process( clk )
	begin
		if rising_edge(clk) then
			if ( rst = '1' ) then
			    output_s <= init;
			else
				output_s <= set or ((not clr) and output_s);
			end if;
		end if;
	end process;

	output <= output_s;


end struct;

-- architecture struct of sr_reg is
	-- signal mux1, mux2, output_s : std_logic;
-- begin

	-- mux1 <= '0' when clr = '1' else output_s;
	-- mux2 <= '1' when set = '1' else mux1;

	-- reg_gen : process( clk )
	-- begin
		-- if rising_edge(clk) then
			-- if ( rst = '1' ) then
			    -- output_s <= '0';
			-- else
				-- output_s <= mux2;
			-- end if;
		-- end if;
	-- end process;

	-- output <= output_s;


-- end struct;
