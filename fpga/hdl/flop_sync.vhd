-- Khaled Hassan
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flop_sync is
    generic(
        CYCLES : natural := 2
    );
    port(
        clk_dest : in  std_logic;
        rst      : in  std_logic;
        d        : in  std_logic;
        q        : out std_logic
    );
end flop_sync;

architecture BHV of flop_sync is
    signal shift_reg : std_logic_vector(CYCLES-1 downto 0);
begin
    
    process (clk_dest, rst) is
    begin
        if rst = '1' then
            shift_reg <= (others => '0');
        elsif rising_edge(clk_dest) then
            shift_reg(CYCLES-2 downto 0) <= shift_reg(CYCLES-1 downto 1);
            shift_reg(CYCLES-1) <= d;
        end if;
    end process;
    
    q <= shift_reg(0);
    
end architecture BHV;

