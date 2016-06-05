library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port(
		clk_osc                           : in  std_logic;
		rst_button                        : in  std_logic;
		matrix_r1, matrix_g1, matrix_b1   : out std_logic;
		matrix_r2, matrix_g2, matrix_b2   : out std_logic;
		matrix_row                        : out std_logic_vector(2 downto 0);
		matrix_clk, matrix_stb, matrix_oe : out std_logic
	);
end entity top_level;

architecture RTL of top_level is
	component clocks_pll is
		port(
			areset : in  STD_LOGIC := '0';
			inclk0 : in  STD_LOGIC := '0';
			c0     : out STD_LOGIC;
			c1     : out STD_LOGIC;
			c2     : out STD_LOGIC;
			locked : out STD_LOGIC
		);
	end component;

	component matrix_driver is
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
	end component;

	signal clk_sys    : std_logic;
	signal clk_sdram  : std_logic;
	signal clk_matrix : std_logic;
	signal pll_locked : std_logic;
	signal rst_sys    : std_logic;
	signal rst_sdram  : std_logic;
	signal rst_matrix : std_logic;

	signal reset_sync_sys    : std_logic_vector(2 downto 0);
	signal reset_sync_sdram  : std_logic_vector(2 downto 0);
	signal reset_sync_matrix : std_logic_vector(2 downto 0);
	signal pll_areset        : std_logic;

	signal reset_gen        : std_logic;
	signal reset_gen_vector : std_logic_vector(30 downto 0);

begin
	pll_areset <= not rst_button;
	clocks_pll_inst : clocks_pll PORT MAP(
			areset => pll_areset,
			inclk0 => clk_osc,
			c0     => clk_sys,
			c1     => clk_sdram,
			c2     => clk_matrix,
			locked => pll_locked
		);

	proc_reset_gen : process(clk_osc, pll_locked) is
	begin
		if pll_locked = '0' then
			reset_gen_vector <= (others => '1');
		elsif rising_edge(clk_osc) then
			reset_gen_vector(reset_gen_vector'high downto 1) <= reset_gen_vector(reset_gen_vector'high - 1 downto 0);
			reset_gen_vector(0)                              <= not pll_locked;
		end if;
	end process proc_reset_gen;

	reset_gen <= reset_gen_vector(reset_gen_vector'high);

	sync_reset_gen_sys : process(clk_sys) is
	begin
		if rising_edge(clk_sys) then
			reset_sync_sys(reset_sync_sys'high downto 1) <= reset_sync_sys(reset_sync_sys'high - 1 downto 0);
			reset_sync_sys(0)                            <= reset_gen;
		end if;
	end process sync_reset_gen_sys;

	rst_sys <= reset_sync_sys(reset_sync_sys'high);

	sync_reset_gen_sdram : process(clk_sdram) is
	begin
		if rising_edge(clk_sdram) then
			reset_sync_sdram(reset_sync_sdram'high downto 1) <= reset_sync_sdram(reset_sync_sdram'high - 1 downto 0);
			reset_sync_sdram(0)                              <= reset_gen;
		end if;
	end process sync_reset_gen_sdram;

	rst_sdram <= reset_sync_sdram(reset_sync_sdram'high);

	sync_reset_gen_matrix : process(clk_matrix) is
	begin
		if rising_edge(clk_matrix) then
			reset_sync_matrix(reset_sync_matrix'high downto 1) <= reset_sync_matrix(reset_sync_matrix'high - 1 downto 0);
			reset_sync_matrix(0)                               <= reset_gen;
		end if;
	end process sync_reset_gen_matrix;

	rst_matrix <= reset_sync_matrix(reset_sync_matrix'high);

	U_MATRIX_DRIVER : component matrix_driver
		generic map(
			BITS_PER_CHANNEL => 8,
			ROWS             => 16,
			COLUMNS          => 32
		)
		port map(
			clk_sys        => clk_sys,
			rst_sys        => rst_sys,
			clk_matrix     => clk_matrix,
			rst_matrix     => rst_matrix,
			matrix_r1      => matrix_r1,
			matrix_g1      => matrix_g1,
			matrix_b1      => matrix_b1,
			matrix_r2      => matrix_r2,
			matrix_g2      => matrix_g2,
			matrix_b2      => matrix_b2,
			matrix_row     => matrix_row,
			matrix_clk_out => matrix_clk,
			matrix_stb     => matrix_stb,
			matrix_oe      => matrix_oe
		);

end architecture RTL;
