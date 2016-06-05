library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix_driver is
	generic(
		BITS_PER_CHANNEL : natural := 8;
		ROWS             : natural := 16;
		COLUMNS          : natural := 32
	);
	port(
		clk_sys                               : in  std_logic;
		rst_sys                               : in  std_logic;
		clk_matrix                            : in  std_logic;
		rst_matrix                            : in  std_logic;
		matrix_r1, matrix_g1, matrix_b1       : out std_logic;
		matrix_r2, matrix_g2, matrix_b2       : out std_logic;
		matrix_row                            : out std_logic_vector(2 downto 0);
		matrix_clk_out, matrix_stb, matrix_oe : out std_logic
	);
end entity matrix_driver;

architecture RTL of matrix_driver is
	component clk_div is
		generic(
			clk_in_freq  : natural;
			clk_out_freq : natural
		);
		port(
			clk_in  : in  std_logic;
			clk_out : out std_logic;
			rst     : in  std_logic
		);
	end component;

	component pulse_sync is
		generic(
			STRETCH_LENGTH : natural := 5
		);
		port(
			clk_in    : in  std_logic;
			clk_out   : in  std_logic;
			pulse_in  : in  std_logic;
			pulse_out : out std_logic
		);
	end component;

	component handshake is
		port(
			clk_src   : in  std_logic;
			clk_dest  : in  std_logic;
			rst       : in  std_logic;
			go        : in  std_logic;
			delay_ack : in  std_logic;
			rcv       : out std_logic;
			ack       : out std_logic
		);
	end component;

	COMPONENT pwm IS
		GENERIC(
			sys_clk         : INTEGER := 50_000_000; --system clock frequency in Hz
			pwm_freq        : INTEGER := 100_000; --PWM switching frequency in Hz
			bits_resolution : INTEGER := 8; --bits of resolution setting the duty cycle
			phases          : INTEGER := 1); --number of output pwms and phases
		PORT(
			clk       : IN  STD_LOGIC;  --system clock
			reset_n   : IN  STD_LOGIC;  --asynchronous reset
			ena       : IN  STD_LOGIC;  --latches in new duty cycle
			duty      : IN  STD_LOGIC_VECTOR(bits_resolution - 1 DOWNTO 0); --duty cycle
			pwm_out   : OUT STD_LOGIC_VECTOR(phases - 1 DOWNTO 0); --pwm outputs
			pwm_n_out : OUT STD_LOGIC_VECTOR(phases - 1 DOWNTO 0)); --pwm inverse outputs
	END COMPONENT;

	type fast_state_t is (S_IDLE, S_LOAD_IMAGE, S_SEND_GRAB, S_WAIT_FOR_GOT);
	signal fast_state : fast_state_t;

	type slow_state_t is (S_GRAB, S_SELECT_ROW, S_COMPARE, S_LOAD_SR, S_SHIFT, S_STROBE);
	signal slow_state : slow_state_t;

	signal grab_fast, grab_slow : std_logic;
	signal got_slow, got_fast   : std_logic;

	type pixel_t is record
		r : std_logic_vector(BITS_PER_CHANNEL - 1 downto 0);
		g : std_logic_vector(BITS_PER_CHANNEL - 1 downto 0);
		b : std_logic_vector(BITS_PER_CHANNEL - 1 downto 0);
	end record;
	type row_t is array (0 to COLUMNS - 1) of pixel_t;
	type matrix_state_t is array (0 to ROWS - 1) of row_t;
	signal matrix_state_fast, matrix_state_slow : matrix_state_t;

	-- matrix clock gating; FSM operates on slow speed, but only want to drive matrix clock when shifting
	signal matrix_clk_en : std_logic;

	signal shift_data_r1 : std_logic_vector(COLUMNS - 1 downto 0);
	signal shift_data_g1 : std_logic_vector(COLUMNS - 1 downto 0);
	signal shift_data_b1 : std_logic_vector(COLUMNS - 1 downto 0);
	signal shift_data_r2 : std_logic_vector(COLUMNS - 1 downto 0) := (others => '0');
	signal shift_data_g2 : std_logic_vector(COLUMNS - 1 downto 0);
	signal shift_data_b2 : std_logic_vector(COLUMNS - 1 downto 0);

	signal pwm_out : std_logic_vector(0 downto 0); -- DigiKey PWM driver gives vector

	signal handshake_delay_ack : std_logic;

	signal rst_pwm : std_logic;

begin
	handshake_delay_ack <= not got_slow;

	U_HANDSHAKE : component handshake
		port map(
			clk_src   => clk_sys,
			clk_dest  => clk_matrix,
			rst       => rst_sys,
			go        => grab_fast,
			delay_ack => handshake_delay_ack,
			rcv       => grab_slow,
			ack       => got_fast
		);

	fast_fsm : process(clk_sys) is
		variable color : unsigned(BITS_PER_CHANNEL - 1 downto 0);
	begin
		if rising_edge(clk_sys) then
			if rst_sys = '1' then
				fast_state <= S_IDLE;
			else
				grab_fast <= '0';
				case fast_state is
					when S_IDLE =>
						fast_state <= S_LOAD_IMAGE;
					when S_LOAD_IMAGE =>
						for row in 0 to ROWS - 1 loop
							for col in 0 to COLUMNS - 1 loop
								if row < ROWS / 2 then
									if col >= 0 and col <= 4 then -- W
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 5 and col <= 8 then -- Y
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									elsif col >= 9 and col <= 13 then -- C 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 14 and col <= 17 then -- G 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									elsif col >= 18 and col <= 22 then -- M 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 23 and col <= 26 then -- R
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									else -- B
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									end if;
								else
									if col >= 0 and col <= 4 then -- B
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 5 and col <= 8 then -- black
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									elsif col >= 9 and col <= 13 then -- M 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 14 and col <= 17 then -- black 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									elsif col >= 18 and col <= 22 then -- C 
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									elsif col >= 23 and col <= 26 then -- black
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(0, BITS_PER_CHANNEL));
									else -- W
										matrix_state_fast(row)(col).r <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).g <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
										matrix_state_fast(row)(col).b <= std_logic_vector(to_unsigned(255, BITS_PER_CHANNEL));
									end if;
								end if;
							end loop;
						end loop;
						fast_state <= S_SEND_GRAB;
					when S_SEND_GRAB =>
						grab_fast  <= '1';
						fast_state <= S_WAIT_FOR_GOT;
					when S_WAIT_FOR_GOT =>
						if got_fast = '1' then
							fast_state <= S_IDLE;
						end if;
				end case;
			end if;
		end if;
	end process fast_fsm;

	slow_fsm : process(clk_matrix) is
		variable row             : natural range 0 to (ROWS / 2) - 1; -- draw row 1 and 8, 2 and 9, etc. simultaneously
		variable column          : natural range 0 to COLUMNS - 1;
		variable color_threshold : unsigned(BITS_PER_CHANNEL - 1 downto 0);
	begin
		if rising_edge(clk_matrix) then
			if rst_matrix = '1' then
				slow_state      <= S_GRAB;
				row             := 0;
				color_threshold := (others => '0');
				column          := 0;
				matrix_clk_en   <= '0';
			else
				-- default values
				matrix_clk_en <= '0';
				got_slow      <= '0';
				matrix_stb    <= '0';

				case slow_state is
					when S_GRAB =>
						color_threshold := (others => '0');
						if grab_slow = '1' then
							matrix_state_slow <= matrix_state_fast;
							got_slow          <= '1';
							slow_state        <= S_SELECT_ROW;
						end if;
					when S_SELECT_ROW =>
						matrix_row <= std_logic_vector(to_unsigned(row, matrix_row'length));
						-- increment row at the end (during strobe) so that COMPARE/LOAD_SR states have correct value
						slow_state <= S_COMPARE;
					when S_COMPARE =>
						for col in 0 to COLUMNS - 1 loop
							-- r1
							if unsigned(matrix_state_slow(row)(col).r) > color_threshold then
								shift_data_r1(col) <= '1';
							else
								shift_data_r1(col) <= '0';
							end if;
							-- g1
							if unsigned(matrix_state_slow(row)(col).g) > color_threshold then
								shift_data_g1(col) <= '1';
							else
								shift_data_g1(col) <= '0';
							end if;
							-- b1
							if unsigned(matrix_state_slow(row)(col).b) > color_threshold then
								shift_data_b1(col) <= '1';
							else
								shift_data_b1(col) <= '0';
							end if;

							-- r2
							if unsigned(matrix_state_slow(row + ROWS / 2)(col).r) > color_threshold then
								shift_data_r2(col) <= '1';
							else
								shift_data_r2(col) <= '0';
							end if;
							-- g2
							if unsigned(matrix_state_slow(row + ROWS / 2)(col).g) > color_threshold then
								shift_data_g2(col) <= '1';
							else
								shift_data_g2(col) <= '0';
							end if;
							-- b2
							if unsigned(matrix_state_slow(row + ROWS / 2)(col).b) > color_threshold then
								shift_data_b2(col) <= '1';
							else
								shift_data_b2(col) <= '0';
							end if;
						end loop;

						column        := 0;
						slow_state    <= S_SHIFT;
						matrix_clk_en <= '1';

					when S_LOAD_SR =>
						null;
					when S_SHIFT =>
						shift_data_r1(shift_data_r1'high - 1 downto 0) <= shift_data_r1(shift_data_r1'high downto 1);
						shift_data_r1(shift_data_r1'high)              <= '0';
						shift_data_g1(shift_data_g1'high - 1 downto 0) <= shift_data_g1(shift_data_g1'high downto 1);
						shift_data_g1(shift_data_g1'high)              <= '0';
						shift_data_b1(shift_data_b1'high - 1 downto 0) <= shift_data_b1(shift_data_b1'high downto 1);
						shift_data_b1(shift_data_b1'high)              <= '0';
						shift_data_r2(shift_data_r2'high - 1 downto 0) <= shift_data_r2(shift_data_r2'high downto 1);
						shift_data_r2(shift_data_r2'high)              <= '0';
						shift_data_g2(shift_data_g2'high - 1 downto 0) <= shift_data_g2(shift_data_g2'high downto 1);
						shift_data_g2(shift_data_g2'high)              <= '0';
						shift_data_b2(shift_data_b2'high - 1 downto 0) <= shift_data_b2(shift_data_b2'high downto 1);
						shift_data_b2(shift_data_b2'high)              <= '0';
						if column = COLUMNS - 1 then
							slow_state <= S_STROBE;
						else
							matrix_clk_en <= '1';
							column        := column + 1;
						end if;
					when S_STROBE =>
						matrix_stb <= '1';

						if row = (ROWS / 2) - 1 then
							row             := 0;
							color_threshold := color_threshold + to_unsigned(1, color_threshold'length);
							if grab_slow = '1' then -- if new frame data available, get it
								slow_state <= S_GRAB;
							else
								slow_state <= S_SELECT_ROW;
							end if;
						else
							row        := row + 1;
							slow_state <= S_SELECT_ROW;
						end if;

				end case;
			end if;
		end if;
	end process slow_fsm;
	matrix_clk_out <= clk_matrix and matrix_clk_en;

	matrix_r1 <= shift_data_r1(shift_data_r1'low);
	matrix_g1 <= shift_data_g1(shift_data_g1'low);
	matrix_b1 <= shift_data_b1(shift_data_b1'low);
	matrix_r2 <= shift_data_r2(shift_data_r2'low);
	matrix_g2 <= shift_data_g2(shift_data_g2'low);
	matrix_b2 <= shift_data_b2(shift_data_b2'low);

	rst_pwm <= not rst_sys;

	U_PWM : component pwm
		generic map(
			sys_clk         => 50_000_000,
			pwm_freq        => 120,
			bits_resolution => 10,
			phases          => 1
		)
		port map(
			clk       => clk_sys,
			reset_n   => rst_pwm,
			ena       => '1',
			duty      => std_logic_vector(to_unsigned(255, 10)),
			pwm_out   => pwm_out,
			pwm_n_out => open
		);

	matrix_oe <= not pwm_out(0);

end architecture RTL;
