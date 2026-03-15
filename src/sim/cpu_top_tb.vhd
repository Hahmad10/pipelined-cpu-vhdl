-- ============================================================================
-- Generic testbench for cpu_top: load any program image into the ROM
-- Provides clock, reset, and in_port. Check results in waveform.
-- Works with any .mem file loaded in ROM.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu_top_tb is
end cpu_top_tb;

architecture behavioral of cpu_top_tb is

    component CPU_Top is
        port(
            clk         : in  std_logic;
            rst_execute : in  std_logic;
            rst_load    : in  std_logic;
            in_port     : in  std_logic_vector(15 downto 0);
            out_port    : out std_logic_vector(15 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 20 ns;
    signal clk         : std_logic := '1';
    signal rst_execute : std_logic := '0';
    signal rst_load    : std_logic := '0';
    signal in_port     : std_logic_vector(15 downto 0) := x"0005";
    signal out_port    : std_logic_vector(15 downto 0);

begin

    UUT: CPU_Top port map (
        clk => clk, rst_execute => rst_execute, rst_load => rst_load,
        in_port => in_port, out_port => out_port
    );

    clk_proc: process
    begin
        clk <= '1'; wait for CLK_PERIOD / 2;
        clk <= '0'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
    begin
        rst_execute <= '1';
        wait until falling_edge(clk);
        rst_execute <= '0';

        -- Let the program run. Check waveform for results.
        -- 05_load_store_immediate: verify R7=0x050F, R1=0x050F, R2=0x0600,
        --                STORE to M[0x0600], LOAD R3=0x050F
        -- 06_loop_multiply_add:     out_port = 0x00BF (191)
        -- 07_loop_nand_shift:       out_port = 0xFFFA (-6)
        wait for 5000 ns;

        report "Simulation complete. Check waveform for results." severity note;
        wait;
    end process;

end behavioral;
