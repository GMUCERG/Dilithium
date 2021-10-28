-- =====================================================================
-- Copyright © 2019-2020 by Cryptographic Engineering Research Group (CERG),
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

-- keccak fsm2 is responsible for keccak computation processing

entity keccak_fsm2 is
	port (
		clk 					: in std_logic;
		rst 					: in std_logic;

		wr_state				: out std_logic;
		sel_xor 				: out std_logic;

		sel_final				: out std_logic;
		ld_rdctr				: out std_logic;
		en_rdctr 				: out std_logic;

		block_ready_clr 		: out std_logic;
		msg_end_clr 			: out std_logic;
		block_ready				: in std_logic;
		msg_end 				: in std_logic;
		lo						: out std_logic;
		output_write_set 		: out std_logic;
		output_busy_set  		: out std_logic;
		output_busy		 		: in  std_logic;
        d                       : in std_logic_vector(31 downto 0);
        output_size             : out std_logic_vector(10 downto 0);
        mode                    : in std_logic_vector(1 downto 0);
        mode_ctrl               : out std_logic_vector(1 downto 0)
        );
end keccak_fsm2;


architecture beh of keccak_fsm2 is
	constant roundnr 		: integer := 24;
	constant log2roundnr	: integer := log2( roundnr );
	constant log2roundnrzeros : std_logic_vector(log2roundnr-1 downto 0) := (others => '0') ;

	type state_type is ( reset, idle, process_block, process_last_block,
    finalization_SHAKE, finalization_SHA, output_data_SHAKE, output_data_SHA,
    shake_process, shake_output_wait);
	signal cstate, nstate : state_type;

	signal pc : std_logic_vector(log2roundnr-1 downto 0);
	signal ziroundnr, li, ei : std_logic;
	signal output_data_s : std_logic;
   	signal sel_xor_set, sel_xor_clr, sel_xor_wire : std_logic;	-- select first message

    signal cnt_output_size_next, cnt_output_size_r : std_logic_vector(31 downto 0);
    signal output_size_next, output_size_r : std_logic_vector(10 downto 0);

    signal b : integer;
    signal hashing_started_r, hashing_started_next : std_logic;
    signal mode_r, mode_next : std_logic_vector(1 downto 0);
begin
    b <= SHAKE256_CAPACITY when mode_r = "11" else SHAKE128_CAPACITY;
	-- fsm2 counter
	proc_counter_gen : countern generic map ( N => log2roundnr )
    port map (
        clk    => clk,
        rst    => rst,
        load   => li,
        en     => ei,
        input  => log2roundnrzeros,
        output => pc
    );
	ziroundnr <= '1' when pc = conv_std_logic_vector(roundnr-1,log2roundnr) else '0';

	-- state process
	cstate_proc : process ( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				cstate <= reset;
                cnt_output_size_r <= (others => '0');
                output_size_r     <= (others => '0');
                mode_r            <= (others => '0');
                hashing_started_r <= '0';
			else
				cstate <= nstate;
                cnt_output_size_r <= cnt_output_size_next;
                output_size_r     <= output_size_next;
                mode_r            <= mode_next;
                hashing_started_r <= hashing_started_next;
			end if;
		end if;
	end process;

	nstate_proc : process (cstate, msg_end, output_busy, block_ready, ziroundnr,
        d, cnt_output_size_r, b, mode, hashing_started_r, output_size_r, mode_r)
    begin
        cnt_output_size_next <= cnt_output_size_r;
        output_size_next     <= output_size_r;
        mode_next            <= mode_r;
        hashing_started_next <= hashing_started_r;
        nstate <= cstate;

        case cstate is
			when reset =>
				nstate <= idle;
			when idle =>
				if ( block_ready = '1' and msg_end = '0' ) then
					nstate <= process_block;
                    if (hashing_started_r = '0') then
                        cnt_output_size_next <= d;
                        mode_next            <= mode;
                        hashing_started_next <= '1';
                    end if;
				elsif (block_ready = '1' and msg_end = '1') then
					nstate <= process_last_block;
                    if (hashing_started_r = '0') then
                        cnt_output_size_next <= d;
                        mode_next            <= mode;
                        hashing_started_next <= '1';
                    end if;
				else
					nstate <= idle;
				end if;

			when process_block =>
				if ( ziroundnr = '0' ) or (ziroundnr = '1' and msg_end = '0' and
                    block_ready = '1') then
					nstate <= process_block;
				elsif (ziroundnr = '1' and msg_end = '1') then
					nstate <= process_last_block;
				else
					nstate <= idle;
				end if;

			when process_last_block =>
				if ( ziroundnr = '0' ) then
					nstate <= process_last_block;
				elsif (ziroundnr = '1') then
                    if ((mode_r = "00")or(mode_r = "01"))then
					    nstate <= finalization_SHA;
                    else
                        nstate <= finalization_SHAKE;
                    end if;
				else
					nstate <= idle;
				end if;

            when finalization_SHA =>
                if (mode_r = "00") then
                    output_size_next <=
                        conv_std_logic_vector(HASH_SIZE_256, output_size'length);
                elsif (mode_r = "01") then
                    output_size_next <=
                        conv_std_logic_vector(HASH_SIZE_512, output_size'length);
                end if;

                if ( output_busy = '1' ) then
                    hashing_started_next <= '0';
                    nstate    <= output_data_SHA;
                elsif (block_ready = '1' and msg_end = '1') then
                    cnt_output_size_next <= d;
                    mode_next <= mode;
                    nstate    <= process_last_block;
                elsif (block_ready = '1') then
                    cnt_output_size_next <= d;
                    mode_next <= mode;
                    nstate    <= process_block;
                else
                    hashing_started_next <= '0';
                    nstate    <= idle;
                end if;

            when output_data_SHA =>
            	if ( output_busy = '1' ) then
					nstate <= output_data_SHA;
				elsif (block_ready = '1' and msg_end = '1') then
                    cnt_output_size_next <= d;
                    hashing_started_next <= '1';
                    mode_next            <= mode;
					nstate               <= process_last_block;
				elsif (block_ready = '1') then
                    cnt_output_size_next <= d;
                    hashing_started_next <= '1';
                    mode_next            <= mode;
					nstate               <= process_block;
				else
					nstate <= idle;
				end if;

			when finalization_SHAKE =>
                if (cnt_output_size_r > b) then
                    nstate <= shake_process;
                    output_size_next <=
                        conv_std_logic_vector(b, output_size_next'length);
                else
                    output_size_next <= cnt_output_size_r(10 downto 0);
    				if ( output_busy = '1' ) then
    					nstate <= output_data_SHAKE;
                        hashing_started_next <= '0';
    				elsif (block_ready = '1' and msg_end = '1') then
                        cnt_output_size_next <= d;
                        mode_next      <= mode;
                        nstate <= process_last_block;
    				elsif (block_ready = '1') then
                        cnt_output_size_next <= d;
                        mode_next      <= mode;
    					nstate <= process_block;
    				else
                        hashing_started_next <= '0';
    					nstate <= idle;
    				end if;
                end if;

			when output_data_SHAKE =>
				if ( output_busy = '1' ) then
					nstate <= output_data_SHAKE;
				elsif (block_ready = '1' and msg_end = '1') then
					nstate <= process_last_block;
                    cnt_output_size_next <= d;
                    mode_next      <= mode;
                    hashing_started_next <= '1';
				elsif (block_ready = '1') then
					nstate <= process_block;
                    cnt_output_size_next <= d;
                    mode_next      <= mode;
                    hashing_started_next <= '1';
				else
					nstate <= idle;
				end if;

            when shake_process =>
                if ( ziroundnr = '0' ) then
                    nstate <= shake_process;
                elsif (ziroundnr = '1') then
                    if (output_busy = '1') then
                        nstate <= shake_output_wait;
                    else
                        cnt_output_size_next <= cnt_output_size_r-b;
                        nstate <= finalization_SHAKE;
                    end if;
                else
                    nstate <= idle;
                end if;

            when shake_output_wait =>
                if (output_busy = '0') then
                    cnt_output_size_next <= cnt_output_size_r-b;
                    nstate <= finalization_SHAKE;
                end if;

		end case;
	end process;

    output_size <= output_size_r;
    mode_ctrl   <= mode_r;

	---- output logic
	output_data_s <= '1' when ((((cstate = finalization_SHA)or
        (cstate = finalization_SHAKE)) and output_busy = '0') or
		(((cstate = output_data_SHA)or(cstate = output_data_SHAKE)) and
        output_busy = '0')) else '0';

	output_write_set <= output_data_s;
	output_busy_set  <= output_data_s;
	lo				 <= output_data_s;

	block_ready_clr	 <= '1' when ((cstate = process_block or
        cstate = process_last_block) and pc = 4) else '0';

	ei <= '1' when (cstate = process_block or cstate = process_last_block or
        cstate = shake_process) else '0';

	li <=  '1' when  (cstate = reset) or ( cstate = idle )or (ziroundnr = '1')
        else '0';


	sf_gen : sr_reg
	generic map ( init => '1' )
	port map (
        rst => rst,
        clk => clk,
        set => sel_xor_set,
        clr => sel_xor_clr,
        output => sel_xor_wire
    );
	sel_xor_set <= '1' when (cstate = reset) or (cstate = process_last_block and ziroundnr = '1') or (cstate = shake_process and ziroundnr = '1') else '0';
	sel_xor_clr <= '1' when sel_xor_wire = '1' and
						((cstate = idle and block_ready = '1') or
						(((cstate = finalization_SHA)or(cstate = finalization_SHAKE)) and output_busy = '0' and block_ready = '1') or
						( ((cstate = output_data_SHA)or(cstate = output_data_SHAKE)) and block_ready = '1' and output_busy = '0')) else '0';
	sel_xor <= sel_xor_wire;


	sel_final <= '1' when  (cstate = idle and block_ready = '1') or
							(cstate = process_block and ziroundnr = '1') or
                            (cstate = finalization_SHAKE and output_busy = '0' and block_ready = '1' and cnt_output_size_r <= b) or
							(cstate = finalization_SHA and output_busy = '0' and block_ready = '1') or
						(((cstate = output_data_SHA)or(cstate = output_data_SHAKE)) and output_busy = '0' and block_ready = '1') else '0';

	ld_rdctr <= '1' when (cstate = idle and block_ready = '1') or ((cstate = process_block) and ziroundnr = '1' and block_ready = '1') or
						(cstate = process_last_block and ziroundnr = '1') or
                     (cstate = shake_process and ziroundnr = '1') else '0';
	en_rdctr <= '1' when ((cstate = process_block or cstate = process_last_block or cstate = shake_process) and ziroundnr = '0') else '0';

	wr_state <= '1' when (cstate = idle and block_ready = '1') or
						(cstate = process_block and ziroundnr = '0') or
						((cstate = process_block) and ziroundnr = '1' and ((msg_end = '0' and block_ready = '1') or (msg_end = '1'))) or
						(cstate = process_last_block) or
                        (cstate = finalization_SHAKE and output_busy = '0' and block_ready = '1' and cnt_output_size_r <= b) or
						(cstate = finalization_SHA and output_busy = '0' and block_ready = '1') or
						(((cstate = output_data_SHA)or(cstate = output_data_SHAKE)) and output_busy = '0' and block_ready = '1') or
                        (cstate = shake_process)
                        else '0';


	msg_end_clr <= '1' when (cstate = idle and block_ready = '1' and msg_end = '1') or
							(cstate = process_block and block_ready = '1' and msg_end = '1' and ziroundnr = '1') or
							(cstate = finalization_SHA and output_busy = '0' and block_ready = '1' and msg_end = '1') or
							(cstate = finalization_SHAKE and output_busy = '0' and block_ready = '1' and msg_end = '1' and cnt_output_size_r <= b) or
							(((cstate = output_data_SHA)or(cstate = output_data_SHAKE))and output_busy = '0' and block_ready = '1' and msg_end = '1') else '0';

end beh;
