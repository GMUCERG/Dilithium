-- =====================================================================
-- Copyright © 2010-2012 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.sha3_pkg.all;
use work.keccak_pkg.all;

entity keccak_control is
	port (
		clk						: in std_logic;
		rst						: in std_logic;

		-- fifo
		src_ready				: in std_logic;
		src_read				: out std_logic;
		dst_ready 				: in std_logic;
		dst_write				: out std_logic;

		-- pad
		clr_len					: out std_logic;
		sel_dec_size 			: out std_logic;
        last_word				: out std_logic;
        spos 					: out std_logic_vector(1 downto 0);

		-- input
		ein						: out std_logic;
		en_ctr					: out std_logic;
		en_len					: out std_logic;
        en_output_len		    : out std_logic;
		sel_cin					: out std_logic;

		sel_xor 				: out std_logic;
		sel_final				: out std_logic;
		ld_rdctr				: out std_logic;
		en_rdctr 				: out std_logic;
		wr_state				: out std_logic;
		final_segment			: in std_logic;

		sel_out					: out std_logic;
		wr_piso 				: out std_logic;

		c						: in std_logic_vector(31 downto 0);
        d						: in std_logic_vector(31 downto 0);
        mode                    : in std_logic_vector(1 downto 0);
        mode_ctrl               : out std_logic_vector(1 downto 0);
        output_size             : out std_logic_vector(10 downto 0);
        last_out_word           : out std_logic
    );
end keccak_control;

architecture struct of keccak_control is
	signal block_ready_set, msg_end_set, load_next_block : std_logic;
	signal block_ready_clr, msg_end_clr      : std_logic;
	signal block_ready, msg_end              : std_logic;
	signal output_write_set, output_busy_set : std_logic;
	signal output_busy                       : std_logic;
	signal output_write                      : std_logic;
	signal output_write_clr, output_busy_clr : std_logic;

	signal ein_wire	                         : std_logic;
	signal en_ctr_wire, en_len_wire, en_output_len_wire : std_logic;

	signal wr_piso_wire, src_read_wire, dst_write_wire : std_logic;
	signal sel_out_wire, sel_out_wire2  : std_logic;
	signal sel_xor_wire, wr_state_wire  : std_logic;
	signal sel_final_wire				: std_logic;
	signal ld_rdctr_wire				: std_logic;
	signal en_rdctr_wire 				: std_logic;

	signal eo_wire                      : std_logic;

    signal output_size_wire             : std_logic_vector(10 downto 0);
begin


	fsm1_gen : entity work.keccak_fsm1(nocounter)
		port map (
            clk             => clk,
            rst             => rst,
            final_segment   =>final_segment,
            c               => c,
            en_ctr          => en_ctr_wire,
            en_len          => en_len_wire,
            en_output_len   => en_output_len_wire,
            ein             => ein_wire,
            load_next_block => load_next_block,
            block_ready_set => block_ready_set,
		    msg_end_set     => msg_end_set,
            src_ready       => src_ready,
            src_read        => src_read_wire,
            mode            => mode,
		    -- pad
		    clr_len         => clr_len,
            sel_dec_size    => sel_dec_size,
            last_word       => last_word,
            spos            => spos
        );



	fsm2_gen : entity work.keccak_fsm2(beh)
		port map(
            clk              => clk,
            rst              => rst,
            wr_state         => wr_state_wire,
		    block_ready_clr  => block_ready_clr,
            msg_end_clr      => msg_end_clr,
		    block_ready      => block_ready,
            msg_end          => msg_end,
            output_write_set => output_write_set,
            output_busy_set  => output_busy_set,
		    output_busy      => output_busy,
            sel_xor          => sel_xor_wire,
            lo               => sel_out_wire,
		    sel_final        => sel_final_wire,
            ld_rdctr         => ld_rdctr_wire,
            en_rdctr         => en_rdctr_wire,
            d                => d,
            output_size      => output_size_wire,
            mode             => mode,
            mode_ctrl        => mode_ctrl
        );

	fsm3_gen : entity work.sha3_fsm3(beh)
		port map (
            clk              => clk,
            rst              => rst,
            eo               => eo_wire,
            output_write     => output_write,
            output_write_clr => output_write_clr,
            output_busy_clr  => output_busy_clr,
		    dst_ready        => dst_ready,
            dst_write        => dst_write_wire,
            output_size      => output_size_wire,
            last_out_word    => last_out_word
        );

	load_next_block <= (not block_ready) or block_ready_clr;

	-- flags of controller which enables handshaking between fsm's

	sr_blk_ready : sr_reg
	port map (
        rst    => rst,
        clk    => clk,
        set    => block_ready_set,
        clr    => block_ready_clr,
        output => block_ready
    );

	sr_msg_end : sr_reg
	port map (
        rst    => rst,
        clk    => clk,
        set    => msg_end_set,
        clr    => msg_end_clr,
        output => msg_end
    );

	sr_output_write : sr_reg
	port map (
        rst    => rst,
        clk    => clk,
        set    => output_write_set,
        clr    => output_write_clr,
        output => output_write
    );

	sr_output_busy : sr_reg
	port map (
        rst    => rst,
        clk    => clk,
        set    => output_busy_set,
        clr    => output_busy_clr,
        output => output_busy
    );

	-- output signals are registered
	ein           <= ein_wire;
	en_len        <= en_len_wire;
    en_output_len <= en_output_len_wire;
	en_ctr        <= en_ctr_wire;
	src_read      <= src_read_wire;

	reg_out: process( clk )
	begin
		if rising_edge( clk ) then
			wr_state  <= wr_state_wire;
			sel_xor   <= sel_xor_wire;
			sel_final <= sel_final_wire;
			ld_rdctr  <= ld_rdctr_wire;
			en_rdctr  <= en_rdctr_wire;

			-- output
			sel_out_wire2 <= sel_out_wire;
		end if;
	end process;

	wr_piso_wire <= eo_wire or sel_out_wire2;
	dst_write    <= dst_write_wire;
	sel_out      <= sel_out_wire2;
	wr_piso      <= wr_piso_wire;
    output_size  <= output_size_wire;

end struct;
