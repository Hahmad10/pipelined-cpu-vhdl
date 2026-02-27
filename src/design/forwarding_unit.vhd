-- ============================================================================
-- Forwarding Unit: RAW Hazard Detection and Data Bypassing
--
-- Compares source register addresses in the EX stage against destination
-- register addresses in the MEM and WB stages. When a match is found and
-- the producing instruction writes to the register file, a forwarding mux
-- select is generated to bypass the stale register file value.
--
-- Priority: EX/MEM forwarding takes priority over MEM/WB forwarding
-- (the most recent producer wins).
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ForwardingUnit is
    port(
        -- Source register addresses from EX stage (the actual addresses
        -- used to read the register file in ID, already muxed for
        -- NAND/SHL/SHR where source 1 is ra instead of rb)
        ex_src1_addr : in  std_logic_vector(2 downto 0);
        ex_src2_addr : in  std_logic_vector(2 downto 0);
        -- Destination from EX/MEM stage
        mem_rd_addr  : in  std_logic_vector(2 downto 0);
        mem_wr_en    : in  std_logic;
        -- Destination from MEM/WB stage
        wb_rd_addr   : in  std_logic_vector(2 downto 0);
        wb_wr_en     : in  std_logic;
        -- Forwarding mux selects
        --   "00" = no forwarding (use register file value)
        --   "01" = forward from EX/MEM (1-cycle-ago result)
        --   "10" = forward from MEM/WB (2-cycle-ago result)
        fwd_a        : out std_logic_vector(1 downto 0);
        fwd_b        : out std_logic_vector(1 downto 0)
    );
end ForwardingUnit;

architecture behavioral of ForwardingUnit is
begin

    -- Forwarding logic for operand A (ALU input 1)
    fwd_a_proc: process(ex_src1_addr, mem_rd_addr, mem_wr_en,
                         wb_rd_addr, wb_wr_en)
    begin
        if (mem_wr_en = '1' and mem_rd_addr = ex_src1_addr) then
            -- EX/MEM has priority: forward from MEM stage
            fwd_a <= "01";
        elsif (wb_wr_en = '1' and wb_rd_addr = ex_src1_addr) then
            -- MEM/WB fallback: forward from WB stage
            fwd_a <= "10";
        else
            -- No hazard: use register file value
            fwd_a <= "00";
        end if;
    end process;

    -- Forwarding logic for operand B (ALU input 2)
    fwd_b_proc: process(ex_src2_addr, mem_rd_addr, mem_wr_en,
                         wb_rd_addr, wb_wr_en)
    begin
        if (mem_wr_en = '1' and mem_rd_addr = ex_src2_addr) then
            fwd_b <= "01";
        elsif (wb_wr_en = '1' and wb_rd_addr = ex_src2_addr) then
            fwd_b <= "10";
        else
            fwd_b <= "00";
        end if;
    end process;

end behavioral;
