-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;


package keccak_pkg is
	-- Keccak parameters
	constant KECCAK_STATE 			: integer := 1600;
	constant KECCAK256_CAPACITY 	: integer := 1088;
	constant KECCAK512_CAPACITY 	: integer := 576;

    -- SHAKE parameters
    constant SHAKE128_CAPACITY      : integer := 1344;
    constant SHAKE256_CAPACITY      : integer := 1088;

	-- width of the interface ports
	constant w						: integer := 64;
	constant LOG2_W 				: integer := 6;
	constant log2roundnr_final256 	: integer := 6;
	constant KECCAK256_WORDS 		: integer:=  KECCAK256_CAPACITY/w;
	constant KECCAK512_WORDS 		: integer:=  KECCAK512_CAPACITY/w;


	-- number of rounds of Keccak
	constant roundnr256	 			: integer := 24;
	constant roundnr_final 			: integer := 1;

	constant CTR_SHORT				: integer := 16;
	constant CTR_FULL				: integer := 64;
	constant CTR_SIZE				: integer := CTR_FULL;

	-- Keccak data types
	type plane  is array (4 downto 0) of std_logic_vector(63 downto 0);
	type state 	is array (4 downto 0) of plane;
	type state_table is array ( 0 to 4 ) of std_logic_vector(KECCAK_STATE/5-1 downto 0);

	-- function descriptions
	function get_keccak_capacity ( hs : integer ) return integer;
	function str2table ( str : std_logic_vector(KECCAK_STATE-1 downto 0) ) return state_table;

    function divceil(a  : natural; b : natural) return natural;
end keccak_pkg;

package body keccak_pkg is
	function get_keccak_capacity ( hs : integer ) return integer is
	begin
		if hs = 256 then
			return KECCAK256_CAPACITY;
		elsif hs = 512 then
			return KECCAK512_CAPACITY;
        else  -- if hs = 128 then
            return SHAKE128_CAPACITY;    
		end if;
	end function get_keccak_capacity;


	function str2table ( str : std_logic_vector(KECCAK_STATE-1 downto 0) ) return state_table is
		variable ret : state_table;
	begin
		for i in 0 to 4 loop
			ret(i) := str(KECCAK_STATE*(5-i)/5-1 downto KECCAK_STATE*(4-i)/5);
		end loop;
		return ret;
	end function str2table;

    function divceil (a : natural; b : natural ) return natural is
    begin
        if(a mod b) > 0 then
            return (a / b) + 1;
        else
            return (a / b);
        end if;
    end function;
end package body keccak_pkg;
