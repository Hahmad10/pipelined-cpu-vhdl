library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ProgramCounter is
    port(
        clk         : in  std_logic;
        rst_execute : in  std_logic;
        rst_load    : in  std_logic;
        pc_load     : in  std_logic;
        stall       : in  std_logic;
        pc_in       : in  std_logic_vector(15 downto 0);
        pc_out      : out std_logic_vector(15 downto 0)
    );
end ProgramCounter;

architecture behavioral of ProgramCounter is
    signal pc_reg : std_logic_vector(15 downto 0) := x"0000";
begin

    process(clk)
    begin
        if falling_edge(clk) then
            -- Priority: resets > stall > load > increment
            if rst_execute = '1' then
                pc_reg <= x"0000";
            elsif rst_load = '1' then
                pc_reg <= x"0002";
            elsif stall = '1' then
                null;  -- hold current value
            elsif pc_load = '1' then
                pc_reg <= pc_in;
            else
                pc_reg <= std_logic_vector(unsigned(pc_reg) + 2);
            end if;
        end if;
    end process;

    pc_out <= pc_reg;

end behavioral;
