-- =====================================================================
-- Copyright © 2019-2020 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- Author: Farnoud Farahmand
-- =====================================================================

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.sha3_pkg.all;
use work.keccak_pkg.all;

-- Groestl fsm1 is responsible for controlling input interface

entity keccak_fsm1 is
	port (
	clk 				: in std_logic;
	rst 				: in std_logic;
	c					: in std_logic_vector(31 downto 0);
	load_next_block		: in std_logic;
	final_segment		: in std_logic;

	ein 				: out std_logic;
	en_ctr 				: out std_logic;
	en_len				: out std_logic;
    en_output_len    	: out std_logic;

	-- pad
	clr_len			    : out std_logic;
	sel_dec_size 	    : out std_logic;
    last_word		    : out std_logic;
    spos 			    : out std_logic_vector(1 downto 0);

	-- Control communication
	block_ready_set 	: out std_logic;
	msg_end_set 		: out std_logic;

	-- FIFO communication
	src_ready 			: in std_logic;
	src_read    		: out std_logic;
    mode                : in std_logic_vector(1 downto 0)
    );
end keccak_fsm1;

architecture nocounter of keccak_fsm1 is
    constant mwseg : integer := 1344/w;
	constant log2mwseg 		: integer := log2( mwseg );
	constant log2mwsegzeros : std_logic_vector(log2mwseg-1 downto 0) := (others => '0');
	-- counter
	signal zjfin, lj, ej : std_logic;
	signal wc : std_logic_vector(log2mwseg-1 downto 0);

	-- fsm sigs
	type state_type is (reset, wait_for_header1, load_block, wait_for_load1,
        wait_for_load2);
	signal cstate_fsm1, nstate : state_type;

	signal f, lf, ef : std_logic;
	signal zc0 : std_logic;

	signal set_start_pad, clr_start_pad, start_pad : std_logic;
	signal spos_sig : std_logic_vector(1 downto 0);
	signal set_full_block, clr_full_block, full_block : std_logic;

	signal zc_more_than_block, comp_lb_e0, extra_block : std_logic;
    signal comp_lb_e0_128, comp_lb_e0_256, comp_lb_e0_512 : std_logic;
	constant zeros : std_logic_vector(63 downto 0) := (others => '0');
    signal mw, mw_seg_2   : integer;
begin

    comp_lb_e0_128 <= '1' when c(10 downto 6) = zeros(10 downto 6) else '0';
    comp_lb_e0_256 <= '1' when c(10 downto 6) = zeros(10 downto 6) else '0';
    comp_lb_e0_512 <= '1' when c(9  downto 6) = zeros(9  downto 6) else '0';

    comp_lb_e0  <=  comp_lb_e0_128 when mode = "10" else
                    comp_lb_e0_256 when mode = "00" else
                    comp_lb_e0_512 when mode = "01" else
                    comp_lb_e0_256;

    mw  <=  KECCAK256_CAPACITY when mode = "00" else
            KECCAK512_CAPACITY when mode = "01" else
            SHAKE128_CAPACITY  when mode = "10" else
            SHAKE256_CAPACITY;

    mw_seg_2  <=  KECCAK256_CAPACITY/w when mode = "00" else
                  KECCAK512_CAPACITY/w when mode = "01" else
                  SHAKE128_CAPACITY/w  when mode = "10" else
                  SHAKE256_CAPACITY/w;

	zc0 <= '1' when c = 0 else '0';
	zc_more_than_block <= '1' when c >= mw else '0';

	-- The only case we need extra block is when the a message is equal to the
	-- block size. Hence, its last word is a full word.
	extra_block <= '1' when c(6 downto 0) = 64 else '0';

	-- final seg register
	sr_final_segment :  sr_reg
	port map ( rst => rst, clk => clk, set => ef, clr => lf, output => f);

	-- fsm1 counter
	word_counter_gen : countern generic map ( n => log2mwseg )
    port map (
        clk    => clk,
        rst    => '0',
        load   => lj,
        en     => ej,
        input  => log2mwsegzeros,
        output => wc
    );
	zjfin <= '1' when wc = conv_std_logic_vector(mw_seg_2-1,log2mwseg) else '0';

	-- state process
	cstate_proc : process ( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				cstate_fsm1 <= reset;
			else
				cstate_fsm1 <= nstate;
			end if;
		end if;
	end process;

	nstate_proc : process (cstate_fsm1, src_ready, load_next_block, zjfin, zc0,
    final_segment, f, full_block)
	begin
		case cstate_fsm1 is
			when reset =>
				nstate <= wait_for_header1;
			when wait_for_header1 =>
				if ( src_ready = '1' ) then
					nstate <= wait_for_header1;
				else
					nstate <= wait_for_load1;
				end if;
			when wait_for_load1 =>
				if (load_next_block = '0') then
					nstate <= wait_for_load1;
				else
					nstate <= load_block;
				end if;
			when load_block =>
				if ((src_ready = '1' and (f = '0' or zc0 = '0' or
                    full_block = '1')) or zjfin = '0') then
					nstate <= load_block;
				elsif (zjfin = '1' and full_block = '0' and f = '1') then
					nstate <= wait_for_load2;
				elsif (src_ready = '0' and zjfin = '1' and f = '0' and
                    zc0 = '1') then
					nstate <= wait_for_header1;
				else
					nstate <= wait_for_load1;
				end if;
		   when wait_for_load2 =>
		   		 if (load_next_block = '0') then
					nstate <= wait_for_load2;
				else
					nstate <= wait_for_header1;
				end if;
		end case;
	end process;

	-- fsm output

	src_read <= '1' when ((cstate_fsm1 = wait_for_header1 and src_ready = '0') or
		(cstate_fsm1 = load_block and src_ready = '0' and
        (zc0 = '0' or full_block = '1'))) else '0';

	ein <= ej;

	ej <= '1' when (cstate_fsm1 = load_block) and ((src_ready = '0' and
        (zc0 = '0' or f = '0' or full_block = '1')) or
		(zc0 = '1' and f = '1' and full_block = '0')) else '0';

        block_ready_set <= '1' when (cstate_fsm1 = load_block and zjfin = '1') and
            ((src_ready = '0' and (zc0 = '0' or f = '0' or full_block = '1')) or
			(zc0 = '1' and f = '1' and full_block = '0')) else '0';


	msg_end_set <= '1' when (cstate_fsm1 = load_block and zjfin = '1' and
        full_block = '0' and f = '1')  else '0';

	lf <= '1' when (cstate_fsm1 = reset) or  (cstate_fsm1 = wait_for_load2 and
        load_next_block = '1')  else '0';

	ef <= '1' when (cstate_fsm1 = wait_for_header1 and final_segment = '1') else '0';

	en_len <= '1' when (src_ready = '0' and cstate_fsm1 = wait_for_header1) else '0';
    en_output_len <= '1' when (src_ready = '0' and cstate_fsm1 = wait_for_header1) else '0';
	en_ctr <= '1' when 	(cstate_fsm1 = wait_for_load1 and
        load_next_block = '1' and zc_more_than_block = '1') or
		(cstate_fsm1 = load_block and full_block = '0' and src_ready = '0' and zc0 = '0')
		else '0';

	lj <= '1' when ((cstate_fsm1 = reset) or (cstate_fsm1 = wait_for_load1) or
        (cstate_fsm1 = wait_for_load2))else '0';

	-- full block
	sr_full_block : sr_reg
		port map (
        rst    => rst,
        clk    => clk,
        set    => set_full_block,
        clr    => clr_full_block,
        output => full_block
    );
	set_full_block <= '1' when (cstate_fsm1 = wait_for_load1 and
        zc_more_than_block = '1') else '0';
	clr_full_block <= '1' when (cstate_fsm1 = load_block and zjfin = '1' and
        ej = '1') else '0';

	-- spos controls
	sr_pos1 : sr_reg
        port map (
        rst    => rst,
        clk    => clk,
        set    => set_start_pad,
        clr    => clr_start_pad,
        output => start_pad
    );
	spos_sig <= "00" when (cstate_fsm1 = load_block and full_block = '0' and
        f = '1' and comp_lb_e0 = '1' and start_pad = '0') else	-- select '0'
		"01" when (cstate_fsm1 = load_block and full_block = '0' and f = '1' and
        comp_lb_e0 = '1' and start_pad = '1') else 	-- select start pad
        "11";
	spos <= spos_sig;
	set_start_pad <= '1' when (cstate_fsm1 = wait_for_header1 and
        final_segment = '1' ) else '0';
	clr_start_pad <= '1' when (cstate_fsm1 = load_block and full_block = '0' and
        f = '1' and comp_lb_e0 = '1' and start_pad = '1' and ej = '1') else '0';

	-- last word
	last_word <= '1' when (cstate_fsm1 = load_block and zjfin = '1' and
        full_block = '0' and f = '1') else '0';

	-- last block counter
	sel_dec_size <= set_full_block;
	clr_len <= '1' when (cstate_fsm1 = load_block and full_block = '0' and
        f = '1' and comp_lb_e0 = '1' and src_ready = '0' and ej = '1') else '0';
end nocounter;
