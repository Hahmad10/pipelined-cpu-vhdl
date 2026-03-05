library ieee;
use ieee.std_logic_1164.all;

entity HazardDetection is
    port(
        -- Load-use hazard detection
        id_src1_addr : in  std_logic_vector(2 downto 0);
        id_src2_addr : in  std_logic_vector(2 downto 0);
        ex_rd_addr   : in  std_logic_vector(2 downto 0);
        ex_mem_read  : in  std_logic;
        -- Branch detection
        branch_taken : in  std_logic;
        -- Outputs
        pc_stall     : out std_logic;
        if_id_stall  : out std_logic;
        id_ex_flush  : out std_logic;
        if_id_flush  : out std_logic
    );
end HazardDetection;

architecture behavioral of HazardDetection is
begin

    process(id_src1_addr, id_src2_addr, ex_rd_addr, ex_mem_read, branch_taken)
    begin
        -- Defaults: no stall, no flush
        pc_stall    <= '0';
        if_id_stall <= '0';
        id_ex_flush <= '0';
        if_id_flush <= '0';

        if branch_taken = '1' then
            -- Branch resolved in EX: flush both IF/ID and ID/EX
            -- to squash the 2 speculatively-fetched instructions.
            -- PC is loaded with branch target by pc_load_sig in cpu_top.
            -- No stall needed (PC gets the new target).
            if_id_flush <= '1';
            id_ex_flush <= '1';

        elsif ex_mem_read = '1' and
              (ex_rd_addr = id_src1_addr or ex_rd_addr = id_src2_addr) then
            -- Load-use hazard: LOAD in EX, dependent instruction in ID.
            -- Stall 1 cycle so MEM/WB forwarding can provide the data.
            pc_stall    <= '1';
            if_id_stall <= '1';
            id_ex_flush <= '1';
        end if;
    end process;

end behavioral;
