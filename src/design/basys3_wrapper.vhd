-- ============================================================================
-- Basys-3 FPGA Wrapper for CPU_Top (FPGA build)
-- Provides divided clock for CPU operation.
-- btnL selects clock mode: manual step (btnR) or auto-run.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Basys3_Wrapper is
    port(
        sys_clk     : in  std_logic;                      -- 100 MHz board clock (W5)
        btnC        : in  std_logic;                      -- Center button: rst_execute
        btnU        : in  std_logic;                      -- Up button: rst_load
        btnR        : in  std_logic;                      -- Right button: manual clock step
        btnL        : in  std_logic;                      -- Left button: toggle auto/manual
        sw          : in  std_logic_vector(15 downto 0);  -- 16 slide switches: in_port
        led         : out std_logic_vector(15 downto 0)   -- 16 LEDs: out_port
    );
end Basys3_Wrapper;

architecture structural of Basys3_Wrapper is

    component CPU_Top is
        port(
            clk         : in  std_logic;
            rst_execute : in  std_logic;
            rst_load    : in  std_logic;
            in_port     : in  std_logic_vector(15 downto 0);
            out_port    : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Debounce counter: 100 MHz / 1_000_000 = 10 ms sample period
    constant DEBOUNCE_LIMIT : integer := 1_000_000;

    -- Clock divider: 100 MHz / 2 = 50 MHz internal clock
    -- The bootloader needs a fast clock for STM32 handshaking.
    -- Divide by 2 gives 50 MHz which is fine.
    signal clk_div      : std_logic := '0';

    -- Debounce signals for buttons
    signal db_counter_r  : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btn_r_stable  : std_logic := '0';
    signal btn_r_prev    : std_logic := '0';
    signal db_counter_c  : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btn_c_stable  : std_logic := '0';
    signal db_counter_u  : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btn_u_stable  : std_logic := '0';
    signal db_counter_l  : integer range 0 to DEBOUNCE_LIMIT := 0;
    signal btn_l_stable  : std_logic := '0';
    signal btn_l_prev    : std_logic := '0';

    -- Clock mode: '0' = auto-run (divided clock), '1' = manual step
    signal manual_mode   : std_logic := '0';

    -- Manual clock step FSM
    signal cpu_clk_reg   : std_logic := '1';
    signal step_state    : integer range 0 to 3 := 0;

    -- CPU clock selection
    signal cpu_clk       : std_logic;

begin

    -- =====================================================================
    -- Clock divider: 100 MHz -> 50 MHz
    -- =====================================================================
    clk_div_proc: process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            clk_div <= not clk_div;
        end if;
    end process;

    -- =====================================================================
    -- Button Debounce Logic
    -- =====================================================================
    debounce_proc: process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            -- btnR
            if btnR /= btn_r_stable then
                if db_counter_r = DEBOUNCE_LIMIT then
                    btn_r_stable <= btnR;
                    db_counter_r <= 0;
                else
                    db_counter_r <= db_counter_r + 1;
                end if;
            else
                db_counter_r <= 0;
            end if;

            -- btnC
            if btnC /= btn_c_stable then
                if db_counter_c = DEBOUNCE_LIMIT then
                    btn_c_stable <= btnC;
                    db_counter_c <= 0;
                else
                    db_counter_c <= db_counter_c + 1;
                end if;
            else
                db_counter_c <= 0;
            end if;

            -- btnU
            if btnU /= btn_u_stable then
                if db_counter_u = DEBOUNCE_LIMIT then
                    btn_u_stable <= btnU;
                    db_counter_u <= 0;
                else
                    db_counter_u <= db_counter_u + 1;
                end if;
            else
                db_counter_u <= 0;
            end if;

            -- btnL
            if btnL /= btn_l_stable then
                if db_counter_l = DEBOUNCE_LIMIT then
                    btn_l_stable <= btnL;
                    db_counter_l <= 0;
                else
                    db_counter_l <= db_counter_l + 1;
                end if;
            else
                db_counter_l <= 0;
            end if;
        end if;
    end process;

    -- =====================================================================
    -- Mode toggle: btnL press toggles between auto and manual clock
    -- =====================================================================
    mode_proc: process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            btn_l_prev <= btn_l_stable;
            if btn_l_stable = '1' and btn_l_prev = '0' then
                manual_mode <= not manual_mode;
            end if;
        end if;
    end process;

    -- =====================================================================
    -- Manual clock step FSM (same as before)
    -- =====================================================================
    clk_step_proc: process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            btn_r_prev <= btn_r_stable;
            case step_state is
                when 0 =>
                    cpu_clk_reg <= '1';
                    if btn_r_stable = '1' and btn_r_prev = '0' then
                        step_state <= 1;
                    end if;
                when 1 =>
                    cpu_clk_reg <= '0';
                    step_state <= 2;
                when 2 =>
                    cpu_clk_reg <= '1';
                    step_state <= 3;
                when 3 =>
                    cpu_clk_reg <= '1';
                    if btn_r_stable = '0' then
                        step_state <= 0;
                    end if;
                when others =>
                    step_state <= 0;
            end case;
        end if;
    end process;

    -- =====================================================================
    -- Clock mux: auto (divided clock) or manual (step FSM)
    -- For bootloader loading: use auto mode (btnL toggle)
    -- For stepping through program: use manual mode
    -- =====================================================================
    cpu_clk <= cpu_clk_reg when manual_mode = '1' else clk_div;

    -- =====================================================================
    -- CPU Instantiation
    -- =====================================================================
    CPU: CPU_Top port map (
        clk         => cpu_clk,
        rst_execute => btn_c_stable,
        rst_load    => btn_u_stable,
        in_port     => sw,
        out_port    => led
    );

end structural;
