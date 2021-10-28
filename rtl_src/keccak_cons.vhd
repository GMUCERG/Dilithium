-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.keccak_pkg.all;

-- asynchronous memory for Keccak constants
-- possible combinations for generic unrolled round factor ur = {1, 2, 3, 4, 6, 8, 12, 24}
entity keccak_cons is
generic (ur : integer:=1);
port(
	addr	 		: in  std_logic_vector(4 downto 0);
	rc				: out std_logic_vector(ur*w-1 downto 0));
end keccak_cons;

architecture keccak_cons of keccak_cons is

type matrix is array (0 to 31) of std_logic_vector(w-1 downto 0);
constant my_rom: matrix :=(
x"0000000000000001", x"0000000000008082", x"800000000000808A", x"8000000080008000",
x"000000000000808B", x"0000000080000001", x"8000000080008081", x"8000000000008009",
x"000000000000008A", x"0000000000000088", x"0000000080008009", x"000000008000000A",
x"000000008000808B", x"800000000000008B", x"8000000000008089", x"8000000000008003",
x"8000000000008002", x"8000000000000080", x"000000000000800A", x"800000008000000A",
x"8000000080008081", x"8000000000008080", x"0000000080000001", x"8000000080008008",
x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000",
x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");

begin

l1_con: if ur = 1 generate
	rc <= my_rom(conv_integer(unsigned(addr)));
end generate;

l2_con: if ur > 1 generate
	l2_gen: for i in 0 to ur-1 generate
		rc(w*(i+1)-1 downto w*i) <= my_rom(conv_integer(unsigned(addr+i)));
	end generate;	
end generate;

end keccak_cons;


