-- =====================================================================
-- Copyright © 2020 by Cryptographic Engineering Research Group (CERG),
-- ECE Department, George Mason University
-- Fairfax, VA, U.S.A.
-- Author: Farnoud Farahmand
-- =====================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.sha3_pkg.all;
use work.keccak_pkg.all;

entity sha3_fsm3 is
	-- generic ( h : integer := 256; w : integer := 64; b : integer :=  KECCAK256_CAPACITY);
    generic ( w : integer := 64);
	port (
		--global
		clk              : in std_logic;
		rst	             : in std_logic;

		-- datapath
		eo               : out std_logic;

		-- fsm 2 handshake signal
		output_write     : in std_logic;
		output_write_clr : out std_logic;
		output_busy_clr  : out std_logic;

		-- fifo
		dst_ready        : in std_logic;
		dst_write        : out std_logic;

        output_size      : in std_logic_vector(10 downto 0);
        last_out_word    : out std_logic
	);
end sha3_fsm3;

architecture beh of sha3_fsm3 is
	-- constant hseg : integer := h/w;
    signal hseg  : std_logic_vector(10 downto 0);
    signal outsize_div_w, b_div_w  : integer;
    -- signal w_sig : std_logic_vector(31 downto 0);
    -- signal output_size_sig : std_logic_vector(31 downto 0);
    -- signal test_sig : std_logic_vector(31 downto 0);
    -- signal test2_sig : std_logic_vector(31 downto 0);
	-- constant log2hseg : integer := log2(hseg);

	signal ek, lk, zkfin : std_logic;
	-- signal kc : std_logic_vector(log2hseg-1 downto 0);
	-- constant log2hsegzeros : std_logic_vector(log2hseg-1 downto 0) := (others => '0');
    signal kc : std_logic_vector(10 downto 0);
    constant log2hsegzeros : std_logic_vector(10 downto 0) := (others => '0');

	type fsm3_state_type is (idle, write_data);
	signal cstate_fsm3, nstate : fsm3_state_type;
begin
    -- w_sig <= conv_std_logic_vector(w, w_sig'length);
    outsize_div_w <= divceil(conv_integer(unsigned(output_size)), w);
    -- b_div_w      <= divceil(b, w);
    -- hseg  <= conv_std_logic_vector(outsize_div_w, hseg'length) when conv_integer(unsigned(output_size)) < b else
    --     conv_std_logic_vector(b_div_w, hseg'length);
    hseg <= conv_std_logic_vector(outsize_div_w, hseg'length);
	-- fsm3 counter
	kcount_gen : countern generic map ( N => 11 ) port map ( clk => clk, rst => '0', load => lk, en => ek, input => log2hsegzeros, output => kc);
	-- zkfin <= '1' when kc = conv_std_logic_vector(hseg-1,32) else '0';
    zkfin <= '1' when kc = hseg-1 else '0';


	cstate_proc : process ( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				cstate_fsm3 <= idle;
			else
				cstate_fsm3 <= nstate;
			end if;
		end if;
	end process;

	nstate_proc : process ( cstate_fsm3, dst_ready, output_write, zkfin)
	begin
		case cstate_fsm3 is
			when idle =>
				if ( output_write = '1') then
					nstate <= write_data;
				else
					nstate <= idle;
				end if;
			when write_data =>
				if ( dst_ready = '0' and zkfin = '1' ) then
					nstate <= idle;
				else
					nstate <= write_data;
				end if;
		end case;
	end process;

	dst_write <= '1' when (cstate_fsm3 = write_data and dst_ready = '0') else '0';
	output_write_clr <= '1' when (cstate_fsm3 = idle and output_write = '1') else '0';
	output_busy_clr  <= '1' when (cstate_fsm3 = write_data and dst_ready = '0' and zkfin = '1') else '0';
	ek <= '1' when (cstate_fsm3 = write_data and dst_ready = '0' and zkfin = '0' ) else '0';
	lk <= '1' when ((cstate_fsm3 = write_data and dst_ready = '0' and zkfin = '1' ) or (cstate_fsm3 = idle and output_write = '1')) else '0';
	eo <= '1' when (cstate_fsm3 = write_data and dst_ready = '0') else '0';

    last_out_word <= zkfin;
end beh;

--architecture registered of sha3_fsm3 is
--	constant hseg : integer := h/w;
--	constant log2hseg : integer := log2(hseg);
--
--	signal ek, lk, zkfin : std_logic;
--	signal kc : std_logic_vector(log2hseg-1 downto 0);
--	constant log2hsegzeros : std_logic_vector(log2hseg-1 downto 0) := (others => '0');
--
--	type fsm3_state_type is (idle, write_data, write_stall);
--	signal cstate_fsm3, nstate : fsm3_state_type;
--begin
--	-- fsm3 counter
--	kcount_gen : countern generic map ( N => log2hseg ) port map ( clk => clk, rst => '0', load => lk, --en => ek, input => log2hsegzeros, output => kc);
--	zkfin <= '1' when kc = conv_std_logic_vector(hseg-1,log2hseg) else '0';
--
--
--	cstate_proc : process ( clk )
--	begin
--		if rising_edge( clk ) then
--			if rst = '1' then
--				cstate_fsm3 <= idle;
--			else
--				cstate_fsm3 <= nstate;
--			end if;
--		end if;
--	end process;
--
--	nstate_proc : process ( cstate_fsm3, dst_ready, output_write, zkfin)
--	begin
--		case cstate_fsm3 is
--			when idle =>
--				if ( output_write = '1' and dst_ready = '0') then
--					nstate <= write_data;
--				else
--					nstate <= idle;
--				end if;
--			when write_data =>
--				if ( zkfin = '1' ) then
--					nstate <= idle;
--				else
--					nstate <= write_stall;
--				end if;
--			when write_stall =>
--				if ( dst_ready = '0' ) then
--					nstate <= write_data;
--				else
--					nstate <= write_stall;
--				end if;
--		end case;
--	end process;
--
--	dst_write <= '1' when (cstate_fsm3 = write_data) else '0';
--	output_write_clr <= '1' when (cstate_fsm3 = idle and output_write = '1' and dst_ready = '0') else --'0';
--	output_busy_clr  <= '1' when (cstate_fsm3 = write_data and zkfin = '1') else '0';
--	ek <= '1' when (cstate_fsm3 = write_data) else '0';
--	lk <= '1' when (cstate_fsm3 = idle) else '0';
--	eo <= '1' when (cstate_fsm3 = write_data) else '0';
--end registered;
