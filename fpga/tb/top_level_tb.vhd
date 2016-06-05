library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is
end entity top_level_tb;

architecture RTL of top_level_tb is
	component top_level is
		port(
			clk_osc                           : in  std_logic;
			rst_button                        : in  std_logic;
			matrix_r1, matrix_g1, matrix_b1   : out std_logic;
			matrix_r2, matrix_g2, matrix_b2   : out std_logic;
			matrix_row                        : out std_logic_vector(2 downto 0);
			matrix_clk, matrix_stb, matrix_oe : out std_logic
		);
	end component;

	signal clk_osc    : std_logic := '0';
	signal rst_button : std_logic := '1';

	signal matrix_r1, matrix_g1, matrix_b1   : std_logic;
	signal matrix_r2, matrix_g2, matrix_b2   : std_logic;
	signal matrix_row                        : std_logic_vector(2 downto 0);
	signal matrix_clk, matrix_stb, matrix_oe : std_logic;
begin
	
	U_UUT : component top_level
		port map(
			clk_osc    => clk_osc,
			rst_button => rst_button,
			matrix_r1  => matrix_r1,
			matrix_g1  => matrix_g1,
			matrix_b1  => matrix_b1,
			matrix_r2  => matrix_r2,
			matrix_g2  => matrix_g2,
			matrix_b2  => matrix_b2,
			matrix_row => matrix_row,
			matrix_clk => matrix_clk,
			matrix_stb => matrix_stb,
			matrix_oe  => matrix_oe
		);
		
	clk_osc <= not clk_osc after 20 ns;
	
end architecture RTL;
