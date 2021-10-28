-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;

package sha3_pkg is
	-- different versions of SHA3 candidates
	constant SHA3_ROUND1	:integer:= 1;
	constant SHA3_ROUND2	:integer:= 2;
	constant SHA3_ROUND3	:integer:= 3;

	-- hash output size
	constant HASH_SIZE_224	:integer:=224;
	constant HASH_SIZE_256	:integer:=256;
	constant HASH_SIZE_384	:integer:=384;
	constant HASH_SIZE_512	:integer:=512;

	-- adder constants
	constant SCCA_BASED : integer := 0;
	constant SCCA_TREE_BASED : integer := 1;
	constant CSA_BASED : integer := 2;
	constant PC_BASED : integer := 3;
	constant CSA_CPA_BASED : integer := 4;
	constant CLA_BASED : integer := 5;
	constant FCCA_BASED : integer := 6;
	constant FCCA_TREE_BASED : integer := 7;
	constant DSP_BASED : integer := 8;

	constant YES : integer := 1;
	constant NO : integer := 0;


	-- family constants
	constant SPARTAN3 : integer := 0;
	constant VIRTEX4 : integer := 1;
	constant VIRTEX5 : integer := 2;

	-- fifo mode constants
	constant ZERO_WAIT_STATE			: integer:=0;
	constant ONE_WAIT_STATE				: integer:=1;
	constant ZERO_WAIT_STATE_PREFETCH		: integer:=2;

	-- implementation constants
	constant DISTRIBUTED				: integer:=0;
	constant BRAM					: integer:=1;
	constant COMBINATIONAL				: integer:=2;

	-- counter constants
	constant COUNTER_STYLE_1				: integer:=1;
	constant COUNTER_STYLE_2				: integer:=2;
	constant COUNTER_STYLE_3				: integer:=3;

	-- logic constants
	constant GND					: std_logic := '0';
	constant VCC					: std_logic := '1';

	-- aes constants
	constant AES_SBOX_SIZE				:integer:=8;
	constant AES_WORD_SIZE				:integer:=32;
	constant AES_BLOCK_SIZE				:integer:=128;
	constant AES_KEY_SIZE				:integer:=128;
	constant AES_ROUND_BASIC			:integer:=1;
	constant AES_ROUND_TBOX				:integer:=2;

	type rom_pad64bit_type is array (0 to 7) of std_logic_vector(7 downto 0);
	constant lookup_sel_lvl2_64bit_pad : rom_pad64bit_type := (
		"10000000", "01000000", "00100000", "00010000",
		"00001000", "00000100", "00000010", "00000001");

	constant lookup_sel_lvl1_64bit_pad : rom_pad64bit_type := (
		"00000000", "10000000",	"11000000",	"11100000",
		"11110000",	"11111000",	"11111100",	"11111110");

    constant lookup_sel_lvl1_64bit_out_zeropad : rom_pad64bit_type := (
    	"11111111", "10000000",	"11000000",	"11100000",
    	"11110000",	"11111000",	"11111100",	"11111110");

	type rom_pad32bit_type is array (0 to 3) of std_logic_vector(3 downto 0);
	constant lookup_sel_lvl2_32bit_pad : rom_pad32bit_type := ("1000", "0100", "0010", "0001");

	constant lookup_sel_lvl1_32bit_pad : rom_pad32bit_type := ("0000", "1000",	"1100",	"1110");


	-- basic shifting and rotating functions
	function shrx ( x : std_logic_vector; y : integer) return std_logic_vector;
	function shlx ( x : std_logic_vector; y : integer) return std_logic_vector;
	function rorx ( x : std_logic_vector; y : integer) return std_logic_vector;
	function rolx ( x : std_logic_vector; y : integer) return std_logic_vector;

	-- log based 2
	function log2 (N: natural) return natural;

	-- switching endianess functions
	-- Note : Names changed for clarity
	-- switch_endian --> switch_endian_word
	-- switch_endian_word --> switch_endian_byte
	function switch_endian_byte (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector;
	function switch_endian_word (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector;

	-- galois field multiplication functions for AES sbox combinational function
	function GF_SQ_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_MUL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_MUL_SCL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0))return STD_LOGIC_VECTOR;
	function GF_INV_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function GF_SQ_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR;
	function MUL_X ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR;
	function MUL_MX ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR;
	function GF_INV_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;
	function GF_MUL_4 ( x, y : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;
	function GF_SQ_SCL_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0))return STD_LOGIC_VECTOR;
	function GF_INV_8 ( x : in  STD_LOGIC_VECTOR (7 downto 0))return STD_LOGIC_VECTOR;


   -- components declaration
	component csa is
		generic (n :integer := 32);
		port (
			a		: in std_logic_vector(n-1 downto 0);
			b		: in std_logic_vector(n-1 downto 0);
			cin		: in std_logic_vector(n-1 downto 0);
			s		: out std_logic_vector(n-1 downto 0);
			cout	: out std_logic_vector(n-1 downto 0));
	end component;

	component fcca is
		generic (n :integer := 32);
		port (
			a		: in std_logic_vector(n-1 downto 0);
			b		: in std_logic_vector(n-1 downto 0);
			s		: out std_logic_vector(n-1 downto 0));
	end component;

	component pc is
	generic (n :integer :=32);
	port (
		a		: in std_logic_vector(n-1 downto 0);
		b		: in std_logic_vector(n-1 downto 0);
		c		: in std_logic_vector(n-1 downto 0);
		d		: in std_logic_vector(n-1 downto 0);
		e		: in std_logic_vector(n-1 downto 0);
		s0		: out std_logic_vector(n-1 downto 0);
		s1		: out std_logic_vector(n-1 downto 0);
		s2		: out std_logic_vector(n-1 downto 0)
	);
	end component;

	component regn is
		generic (
			N : integer := 32;
			init : std_logic_vector
		);
		port (
		    clk : in std_logic;
			rst : in std_logic;
		    en : in std_logic;
			input  : in std_logic_vector(N-1 downto 0);
	        output : out std_logic_vector(N-1 downto 0)
		);
	end component;


	component d_ff is
	port(
		clk		: in std_logic;
		ena		: in std_logic;
		rst		: in std_logic;
		d		: in std_logic;
		q		: out std_logic);
	end component;

	component piso is
		generic (
			N	: integer := 512;	--inputs
			M	: integer := 32		--outputs -- N must be divisible by M
		);
		port (
			clk 	 : in std_logic;
			en   : in std_logic;
			sel	 : in std_logic;
			input  : in std_logic_vector(N-1 downto 0);
			output : out std_logic_vector(M-1 downto 0)
		);
	end component;

	component sipo is
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
	end component;

	component countern is
		generic (
		    N : integer := 2;
		    step:integer:=1;
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
	end component;

	component decountern is
		generic (
		n : integer := 64;
			sub : integer := 1
		);
		port (
			clk : in std_logic;
			rst		: in std_logic;
		    load : in std_logic;
		    en : in std_logic;
			input  : in std_logic_vector(n-1 downto 0);
			--sub    : in std_logic_vector(n-1 downto 0);
	        output : out std_logic_vector(n-1 downto 0)
		);
	end component;

	component sr_reg is
		generic ( init : std_logic := '0' );
		port (
			rst			: in std_logic;
			clk 		: in std_logic;
			set     	: in std_logic;
			clr         : in std_logic;
			output		: out std_logic
		);
	end component;

	component sync_clock is
		generic (
		fr : integer := 1
		);
		port (
			rst		   	: in std_logic;
			fast_clock 	: in std_logic;
			slow_clock 	: in std_logic;
			sync		: out std_logic
		);
	end component;

	component fifo_ram is
		generic (
			fifo_mode	: integer := ZERO_WAIT_STATE;
			depth 		: integer := 512;
			log2depth  	: integer := 9;
			n 		: integer := 64 );
		port (
			clk 		: in  std_logic;
			write 		: in  std_logic;
			rd_addr 	: in  std_logic_vector (log2depth-1 downto 0);
			wr_addr 	: in  std_logic_vector (log2depth-1 downto 0);
			din 		: in  std_logic_vector (n-1 downto 0);
			dout 		: out std_logic_vector (n-1 downto 0));
	end component;

	component fifo
		generic (
			fifo_mode	: integer := ONE_WAIT_STATE;
			depth 		: integer := 64;
			log2depth 	: integer := 6;
			N 		: integer := 32);
		port (
			clk				: in std_logic;
			rst				: in std_logic;
			write			: in std_logic;
			read			: in std_logic;
			din 			: in std_logic_vector(n-1 downto 0);
			dout	 		: out std_logic_vector(n-1 downto 0);
			full			: in std_logic;
			empty 			: out std_logic);
	end component;

	component aes_sbox_sync is
	port(
			clk		: in std_logic;
			input 		: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
	        	output 		: out std_logic_vector(AES_SBOX_SIZE-1 downto 0));
	end component;

	component aes_sbox is
	generic (rom_style :integer:=DISTRIBUTED);
	port(

			input 		: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
	        output 		: out std_logic_vector(AES_SBOX_SIZE-1 downto 0));
	end component;

	component aes_mul is
	generic (cons :integer := 3);
	port(
		input 		: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
	        output 		: out std_logic_vector(AES_SBOX_SIZE-1 downto 0));
	end component;

	component aes_mixcolumn is
	port(
		input 		: in std_logic_vector(AES_WORD_SIZE-1 downto 0);
	     output 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));
	end component;


	component aes_shiftrow is
	generic (n	:integer := AES_BLOCK_SIZE;	s 	:integer := AES_SBOX_SIZE);
	port(
		input 		: in std_logic_vector(n-1 downto 0);
	    output 		: out std_logic_vector(n-1 downto 0));
	end component;

	component aes_tbox0 is
	port (
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));
	end component;

	component aes_tbox1 is
	port (
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));
	end component;

	component aes_tbox2 is
	port (
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));
	end component;

	component aes_tbox3 is
	port (
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));
	end component;

	component aes_tbox0_sync is
	port (
		clk 		: in std_logic;
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));

	end component;

	component aes_tbox1_sync is
	port (
		clk 		: in std_logic;
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));

	end component;

		component aes_tbox2_sync is
	port (
		clk 		: in std_logic;
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));

	end component;

	component aes_tbox3_sync is
	port (
		clk 		: in std_logic;
		address 	: in std_logic_vector(AES_SBOX_SIZE-1 downto 0);
		dout 		: out std_logic_vector(AES_WORD_SIZE-1 downto 0));

	end component;

	component aes_round is
	generic (rom_style :integer:=DISTRIBUTED);
	port(
		input 		: in std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
		key			: in std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
        output 		: out std_logic_vector(AES_BLOCK_SIZE-1 downto 0));
	end component;

	component aes_round_sync is
	generic (rom_style :integer:=DISTRIBUTED);
	port(
		clk			: in std_logic;
		input 		: in std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
		key			: in std_logic_vector(AES_BLOCK_SIZE-1 downto 0);
        output 		: out std_logic_vector(AES_BLOCK_SIZE-1 downto 0));
	end component;

	component sha3_fsm3 is
		generic ( w : integer := 64; h : integer := 256 );
		port (
			--global
			clk  : in std_logic;
			rst		: in std_logic;

			-- datapath
			eo : out std_logic;

			-- fsm 2 handshake signal
			output_write : in std_logic;
			output_write_clr : out std_logic;
			output_busy_clr  : out std_logic;

			-- fifo
			dst_ready : in std_logic;
			dst_write : out std_logic
		);
	end component;

	component aes_sbox_logic is
	    Port ( S_IN : in  STD_LOGIC_VECTOR (7 downto 0);
	           S_OUT : out  STD_LOGIC_VECTOR (7 downto 0));
	end component;

	component shfreg is
	generic (
		width : integer := 32;
		depth : integer := 16 );
	port (
		clk : in std_logic;
		en : in std_logic;
		i : in std_logic_vector(width-1 downto 0);
		o : out std_logic_vector(width-1 downto 0) );
	end component;

	component adder is
	generic (
		adder_type : integer:= SCCA_BASED;
		n : integer := 64);
	port(
		a : in std_logic_vector(n-1 downto 0);
		b : in std_logic_vector(n-1 downto 0);
		s : out std_logic_vector(n-1 downto 0)
	);
	end component;
end sha3_pkg;

-- functions description
package body sha3_pkg is
	function shrx ( x : std_logic_vector; y : integer) return std_logic_vector is
		variable zeros	: std_logic_vector(y-1 downto 0) := (others => '0');
	begin
		return (zeros & x(x'high downto y));
	end shrx;

	function shlx ( x : std_logic_vector; y : integer) return std_logic_vector is
		variable zeros	: std_logic_vector(y-1 downto 0) := (others => '0');
	begin
		return (x(x'high-y downto x'low) & zeros);
	end shlx;

	function rorx ( x : std_logic_vector; y : integer) return std_logic_vector is
	begin
		return (x(y-1 downto x'low) & x(x'high downto y));
	end rorx;

	function rolx ( x : std_logic_vector; y : integer) return std_logic_vector is
	begin
		return (x(x'high-y downto x'low) & x(x'high downto x'high-y+1));
	end rolx;

	function log2 (N: natural) return natural is
	begin
--		 if N < 2 then
--			 return 1;
--		 else
--			 return 1 + log2(N/2);
--		 end if;

		 if ( N = 0 ) then
			 return 0;
		 elsif N <= 2 then
			 return 1;
		 else
			if (N mod 2 = 0) then
				return 1 + log2(N/2);
			else
				return 1 + log2((N+1)/2);
			end if;
		 end if;
	end;

	function switch_endian_byte (  x : std_logic_vector; width : integer; w : integer ) return std_logic_vector is
		variable xseg : integer := width/w;
		variable wseg : integer := w/8;
		variable retval : std_logic_vector(width-1 downto 0);
	begin
		for i in xseg downto 1 loop
			for j in 0 to wseg-1 loop
				retval(i*w - 1 - j*8 downto i*w - 8 - j*8 ) := x(i*w - 1 - (wseg-1-j)*8 downto i*w - 8 - (wseg-1-j)*8);
			end loop;
		end loop;
		return(retval);
	end switch_endian_byte;

	function switch_endian_word ( x : std_logic_vector; width : integer; w : integer ) return std_logic_vector is
		variable xseg : integer := width/w;
		variable retval : std_logic_vector(width-1 downto 0);
	begin
		for i in xseg downto 1 loop
			retval(i*w - 1 downto w*(i-1) ) := x(w*(xseg-i+1) - 1 downto w*(xseg-i));
		end loop;
		return(retval);
	end switch_endian_word;

	function GF_SQ_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
		y := x(1) & (x(1) xor x(0));
		return y;
	end GF_SQ_SCL_2;


	function GF_SCL_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
		y := x(0) & (x(1) xor x(0));
		return y;
	end GF_SCL_2;


	function GF_MUL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable o : STD_LOGIC_VECTOR (1 downto 0);
	begin
		o := (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(1) and y(1))) & (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0)));
		return o;
	end GF_MUL_2;


	function GF_MUL_SCL_2 ( x,y : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable o : STD_LOGIC_VECTOR (1 downto 0);
	begin
		o := (((x(1) xor x(0)) and (y(1) xor y(0))) xor (x(0) and y(0))) & ((x(1) and y(1)) xor (x(0) and y(0)));
		return o;
	end GF_MUL_SCL_2;


	function GF_INV_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
		y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_INV_2;


	function GF_SQ_2 ( x : in  STD_LOGIC_VECTOR (1 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (1 downto 0);
	begin
	  	y(1) := x(0);
	  	y(0) := x(1);
		return y;
	end GF_SQ_2;

	function MUL_X ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (7 downto 0);
	begin
		y(7) := x(7) xor x(6) xor x(5) xor x(2) xor x(1) xor x(0);
		y(6) := x(6) xor x(5) xor x(4) xor x(0);
		y(5) := x(6) xor x(5) xor x(1) xor x(0);
		y(4) := x(7) xor x(6) xor x(5) xor x(0);
		y(3) := x(7) xor x(4) xor x(3) xor x(1) xor x(0);
		y(2) := x(0);
		y(1) := x(6) xor x(5) xor x(0);
		y(0) := x(6) xor x(3) xor x(2) xor x(1) xor x(0);
		return y;
	end MUL_X;

	function MUL_MX ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (7 downto 0);
	begin
		y(7) := x(5) xor x(3);
		y(6) := x(7) xor x(3);
		y(5) := x(6) xor x(0);
		y(4) := x(7) xor x(5) xor x(3);
		y(3) := x(7) xor x(6) xor x(5) xor x(4) xor x(3);
		y(2) := x(6) xor x(5) xor x(3) xor x(2) xor x(0);
		y(1) := x(5) xor x(4) xor x(1);
		y(0) := x(6) xor x(4) xor x(1);
	return y;
	end MUL_MX;



	function GF_INV_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (3 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :STD_LOGIC_VECTOR (1 downto 0);
	begin
		r1 := x(3 downto 2);
		r0 := x(1 downto 0);
		SQ_IN := r1 xor r0;
		SQ_OUT := GF_SQ_SCL_2 ( x => SQ_IN);
		MUL_1_OUT := GF_MUL_2( x => r1, y => r0);
		GF_INV_IN := MUL_1_OUT xor SQ_OUT;
		GF_INV_OUT := GF_INV_2(x => GF_INV_IN);
		MUL_2_OUT := GF_MUL_2 ( x => r1, y => GF_INV_OUT);
		MUL_3_OUT := GF_MUL_2 ( x => GF_INV_OUT, y => r0);
		y := MUL_3_OUT & MUL_2_OUT;
		return y;
	end GF_INV_4;


	function GF_MUL_4 ( x,y : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is
		variable o : STD_LOGIC_VECTOR (3 downto 0);
		variable tao1, tao0, delta1, delta0, fi1, fi0, tmp1, tmp0, RES_MUL1, RES_MUL0,RES_MUL_SCL: std_logic_vector (1 downto 0);
	begin
		tao1 := x(3 downto 2);
		tao0 := x(1 downto 0);
		delta1 := y(3 downto 2);
		delta0 := y(1 downto 0);
		tmp1 := tao1 xor tao0;
		tmp0 := delta1 xor delta0;
		RES_MUL1 := GF_MUL_2 ( x=> tao1, y=> delta1);
		RES_MUL0 := GF_MUL_2 ( x=> tao0, y=> delta0);
		RES_MUL_SCL := GF_MUL_SCL_2( x=> tmp1, y=> tmp0);
		fi1 := RES_MUL1 xor RES_MUL_SCL;
		fi0 := RES_MUL0 xor RES_MUL_SCL;
		o := fi1 & fi0;
		return o;
	end GF_MUL_4;

	function GF_SQ_SCL_4 ( x : in  STD_LOGIC_VECTOR (3 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (3 downto 0);
		variable tao1, tao0, delta1, delta0, tmp1, tmp0: std_logic_vector (1 downto 0);
	begin
		tao1 := x(3 downto 2);
		tao0 := x(1 downto 0);
		tmp1 := tao1 xor tao0;
		tmp0 := GF_SCL_2 ( x => tao0);
		delta1 := GF_SQ_2( x=> tmp1);
		delta0 := GF_SQ_2 ( x=> tmp0);
		y := delta1 & delta0;
		return y;
	end GF_SQ_SCL_4;


	function GF_INV_8 ( x : in  STD_LOGIC_VECTOR (7 downto 0)) return STD_LOGIC_VECTOR is
		variable y : STD_LOGIC_VECTOR (7 downto 0);
		variable r0, r1, SQ_IN, SQ_OUT, MUL_1_OUT, GF_INV_IN, GF_INV_OUT, MUL_2_OUT , MUL_3_OUT :STD_LOGIC_VECTOR (3 downto 0);
	begin
		r1 := x(7 downto 4);
		r0 := x(3 downto 0);
		SQ_IN := r1 xor r0;
		SQ_OUT := GF_SQ_SCL_4 ( x => SQ_IN);
		MUL_1_OUT := GF_MUL_4 ( x => r1, y => r0);
		GF_INV_IN := MUL_1_OUT xor SQ_OUT;
		GF_INV_OUT := GF_INV_4 (x => GF_INV_IN);
		MUL_2_OUT := GF_MUL_4 ( x => r1, y => GF_INV_OUT);
		MUL_3_OUT := GF_MUL_4 ( x => GF_INV_OUT, y => r0);
		y := MUL_3_OUT  & MUL_2_OUT;
		return y;
	end GF_INV_8;

end package body sha3_pkg;
