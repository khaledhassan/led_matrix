library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port(
		clk_osc                           : in  std_logic;
		rst_button                        : in  std_logic;
		matrix_r, matrix_g, matrix_b      : out std_logic_vector(1 downto 0);
		matrix_clk, matrix_stb, matrix_oe : out std_logic
	);
end entity top_level;

architecture RTL of top_level is
	component sopc is
		port(
			clk_osc_clk      : in  std_logic := 'X'; -- clk
			rst_button_reset : in  std_logic := 'X'; -- reset
			clk_sys_clk      : out std_logic; -- clk
			clk_sdram_clk    : out std_logic; -- clk
			rst_sys_reset    : out std_logic -- reset
		);
	end component sopc;

	signal clk_sys   : std_logic;
	signal clk_sdram : std_logic;
	signal rst_sys   : std_logic;

begin
	U_SOPC : component sopc
		port map(
			clk_osc_clk      => clk_osc,    -- clk_osc.clk
			rst_button_reset => rst_button, -- rst_button.reset
			clk_sys_clk      => clk_sys,    -- clk_sys.clk
			clk_sdram_clk    => clk_sdram,  -- clk_sdram.clk
			rst_sys_reset    => rst_sys     -- rst_sys.reset
		);

end architecture RTL;
