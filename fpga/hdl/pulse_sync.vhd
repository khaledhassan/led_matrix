library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_sync is
	generic (
		STRETCH_LENGTH : natural := 5
	);
	port (
		clk_in : in std_logic;
		clk_out : in std_logic;
		pulse_in : in std_logic;
		pulse_out : out std_logic
	);
end entity pulse_sync;

architecture RTL of pulse_sync is
	signal stretched_in : std_logic_vector(STRETCH_LENGTH-1 downto 0);
	signal sync_stretched : std_logic_vector(2 downto 0); -- should be (at least) 3 FFs, compare the upper 2 to generate pulse
	
begin

	stretch_in : process (clk_in) is
	begin
		if rising_edge(clk_in) then
			if pulse_in = '1' then
				stretched_in <= (others => '1');
			else
				stretched_in(STRETCH_LENGTH-1 downto 1) <= stretched_in(STRETCH_LENGTH-2 downto 0);
				stretched_in(0) <= '0';
			end if;
		end if;
	end process stretch_in;
	
	sync_stretched_proc : process (clk_out) is
	begin
		if rising_edge(clk_out) then
			sync_stretched(sync_stretched'high downto 1) <= sync_stretched(sync_stretched'high-1 downto 0);
			sync_stretched(0) <= stretched_in(stretched_in'high);
		end if;
	end process sync_stretched_proc;
	
	output_pulse : process (clk_out) is
	begin
		if rising_edge(clk_out) then
			pulse_out <= sync_stretched(sync_stretched'high-1) and (sync_stretched(sync_stretched'high) xor sync_stretched(sync_stretched'high-1));
		end if;
	end process output_pulse;
	

end architecture RTL;
