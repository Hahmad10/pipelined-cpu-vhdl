library ieee;
use ieee.std_logic_1164.all;

entity FlagRegister is
    port(
        clk   : in  std_logic;
        wr_en : in  std_logic;
        z_in  : in  std_logic;
        n_in  : in  std_logic;
        z_out : out std_logic;
        n_out : out std_logic
    );
end FlagRegister;

architecture behavioral of FlagRegister is
    signal z_reg : std_logic := '0';
    signal n_reg : std_logic := '0';
begin

    process(clk)
    begin
        if falling_edge(clk) then
            if wr_en = '1' then
                z_reg <= z_in;
                n_reg <= n_in;
            end if;
        end if;
    end process;

    z_out <= z_reg;
    n_out <= n_reg;

end behavioral;
