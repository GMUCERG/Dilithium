-- =====================================================================
-- Copyright © 2019-2020 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- Author: Farnoud Farahmand
-- =====================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity keccak_bytepad is
	generic( w:integer:=64);
    Port ( din_input        : in  std_logic_vector (w-1 downto 0);
           din_output       : out  std_logic_vector (w-1 downto 0);
           sel_pad_location : in  std_logic_vector(w/8-1 downto 0);
		   sel_din 			: in  std_logic_vector(w/8-1 downto 0);
		   last_word        : in std_logic;
           mode             : in std_logic_vector(1 downto 0);
           dout_input       : in  std_logic_vector (w-1 downto 0);
           dout_output      : out  std_logic_vector (w-1 downto 0);
           sel_dout 	    : in  std_logic_vector(w/8-1 downto 0);
           last_out_word    : in std_logic
    );
end keccak_bytepad;

architecture struct of keccak_bytepad is
	type byte_pad_type is array (w/8-1 downto 0) of std_logic_vector(7 downto 0);
	signal byte_pad_wire	: byte_pad_type;
	signal sel_last_mux : std_logic_vector(1 downto 0);
    signal first_byte, first_last_byte : std_logic_vector(7 downto 0);
    signal dout_output_padded : std_logic_vector (w-1 downto 0);

begin
	byte_pad_gen : for i in w/8-1 downto 1 generate
        byte_pad_wire(i)<= first_byte when sel_pad_location(i) = '1' else X"00";
		din_output(8*(i+1)-1 downto 8*i) <= din_input(8*(i+1)-1 downto 8*i) when
            sel_din(i) = '1' else byte_pad_wire(i);
	end generate;

	sel_last_mux    <=  last_word & sel_pad_location(0);
    first_byte      <= x"1F" when ((mode="11")or(mode="10")) else x"06";
    first_last_byte <= x"9F" when ((mode="11")or(mode="10")) else x"86";
	with sel_last_mux(1 downto 0) select
	byte_pad_wire(0)  <= x"00"           when "00",
						 first_byte      when "01",
						  x"80"          when "10",
						 first_last_byte when OTHERS;
	din_output(7 downto 0)<=din_input(7 downto 0) when sel_din(0)='1' else byte_pad_wire(0);

-- output zero padding
    byte_out_zeropad_gen : for i in w/8-1 downto 0 generate
		dout_output_padded(8*(i+1)-1 downto 8*i) <=
            dout_input(8*(i+1)-1 downto 8*i) when sel_dout(i) = '1' else x"00";
	end generate;
    dout_output <= dout_output_padded when last_out_word = '1' else dout_input;

end struct;
