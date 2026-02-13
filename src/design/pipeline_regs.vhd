-- ============================================================================
-- Pipeline Registers for 5-stage CPU
-- Contains four entities: PipeReg_IF_ID, PipeReg_ID_EX, PipeReg_EX_MEM, PipeReg_MEM_WB
-- All clocked on falling edge. Flush has priority over stall.
-- ============================================================================


-- ============================================================================
-- IF/ID Pipeline Register
-- Carries: fetched instruction + PC+2
-- Control: stall (hold), flush (clear to NOP)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity PipeReg_IF_ID is
    port(
        clk          : in  std_logic;
        stall        : in  std_logic;
        flush        : in  std_logic;
        -- Data in
        instr_in     : in  std_logic_vector(15 downto 0);
        pc_plus2_in  : in  std_logic_vector(15 downto 0);
        -- Data out
        instr_out    : out std_logic_vector(15 downto 0);
        pc_plus2_out : out std_logic_vector(15 downto 0)
    );
end PipeReg_IF_ID;

architecture behavioral of PipeReg_IF_ID is
begin
    process(clk)
    begin
        if falling_edge(clk) then
            if flush = '1' then
                instr_out    <= (others => '0');
                pc_plus2_out <= (others => '0');
            elsif stall = '0' then
                instr_out    <= instr_in;
                pc_plus2_out <= pc_plus2_in;
            end if;
            -- stall='1' and flush='0': hold current values
        end if;
    end process;
end behavioral;


-- ============================================================================
-- ID/EX Pipeline Register
-- Carries: decoded operands, register addresses, and all control signals
-- Control: flush (clear to bubble -all write enables to '0')
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity PipeReg_ID_EX is
    port(
        clk            : in  std_logic;
        flush          : in  std_logic;
        -- Data in
        rd1_in         : in  std_logic_vector(15 downto 0);
        rd2_in         : in  std_logic_vector(15 downto 0);
        pc_plus2_in    : in  std_logic_vector(15 downto 0);
        imm_in         : in  std_logic_vector(15 downto 0);
        -- Register addresses in
        ra_in          : in  std_logic_vector(2 downto 0);
        rb_in          : in  std_logic_vector(2 downto 0);
        rc_in          : in  std_logic_vector(2 downto 0);
        -- Muxed source addresses (for forwarding unit)
        src1_addr_in   : in  std_logic_vector(2 downto 0);
        src2_addr_in   : in  std_logic_vector(2 downto 0);
        -- Control signals in
        reg_wr_en_in   : in  std_logic;
        alu_mode_in    : in  std_logic_vector(2 downto 0);
        alu_src_in     : in  std_logic;
        mem_wr_en_in   : in  std_logic;
        mem_to_reg_in  : in  std_logic;
        branch_type_in : in  std_logic_vector(2 downto 0);
        io_op_in       : in  std_logic_vector(1 downto 0);
        loadimm_en_in  : in  std_logic;
        loadimm_sel_in : in  std_logic;
        mov_en_in      : in  std_logic;
        flag_wr_en_in  : in  std_logic;
        -- Data out
        rd1_out         : out std_logic_vector(15 downto 0);
        rd2_out         : out std_logic_vector(15 downto 0);
        pc_plus2_out    : out std_logic_vector(15 downto 0);
        imm_out         : out std_logic_vector(15 downto 0);
        -- Register addresses out
        ra_out          : out std_logic_vector(2 downto 0);
        rb_out          : out std_logic_vector(2 downto 0);
        rc_out          : out std_logic_vector(2 downto 0);
        -- Muxed source addresses out (for forwarding unit)
        src1_addr_out   : out std_logic_vector(2 downto 0);
        src2_addr_out   : out std_logic_vector(2 downto 0);
        -- Control signals out
        reg_wr_en_out   : out std_logic;
        alu_mode_out    : out std_logic_vector(2 downto 0);
        alu_src_out     : out std_logic;
        mem_wr_en_out   : out std_logic;
        mem_to_reg_out  : out std_logic;
        branch_type_out : out std_logic_vector(2 downto 0);
        io_op_out       : out std_logic_vector(1 downto 0);
        loadimm_en_out  : out std_logic;
        loadimm_sel_out : out std_logic;
        mov_en_out      : out std_logic;
        flag_wr_en_out  : out std_logic
    );
end PipeReg_ID_EX;

architecture behavioral of PipeReg_ID_EX is
begin
    process(clk)
    begin
        if falling_edge(clk) then
            if flush = '1' then
                -- Clear data
                rd1_out         <= (others => '0');
                rd2_out         <= (others => '0');
                pc_plus2_out    <= (others => '0');
                imm_out         <= (others => '0');
                ra_out          <= (others => '0');
                rb_out          <= (others => '0');
                rc_out          <= (others => '0');
                src1_addr_out   <= (others => '0');
                src2_addr_out   <= (others => '0');
                -- Clear control to safe defaults (no writes, no branches)
                reg_wr_en_out   <= '0';
                alu_mode_out    <= (others => '0');
                alu_src_out     <= '0';
                mem_wr_en_out   <= '0';
                mem_to_reg_out  <= '0';
                branch_type_out <= (others => '0');
                io_op_out       <= (others => '0');
                loadimm_en_out  <= '0';
                loadimm_sel_out <= '0';
                mov_en_out      <= '0';
                flag_wr_en_out  <= '0';
            else
                -- Normal latch
                rd1_out         <= rd1_in;
                rd2_out         <= rd2_in;
                pc_plus2_out    <= pc_plus2_in;
                imm_out         <= imm_in;
                ra_out          <= ra_in;
                rb_out          <= rb_in;
                rc_out          <= rc_in;
                src1_addr_out   <= src1_addr_in;
                src2_addr_out   <= src2_addr_in;
                reg_wr_en_out   <= reg_wr_en_in;
                alu_mode_out    <= alu_mode_in;
                alu_src_out     <= alu_src_in;
                mem_wr_en_out   <= mem_wr_en_in;
                mem_to_reg_out  <= mem_to_reg_in;
                branch_type_out <= branch_type_in;
                io_op_out       <= io_op_in;
                loadimm_en_out  <= loadimm_en_in;
                loadimm_sel_out <= loadimm_sel_in;
                mov_en_out      <= mov_en_in;
                flag_wr_en_out  <= flag_wr_en_in;
            end if;
        end if;
    end process;
end behavioral;


-- ============================================================================
-- EX/MEM Pipeline Register
-- Carries: ALU result, memory write data, destination, flags, and MEM/WB control
-- No stall or flush -plain latch
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity PipeReg_EX_MEM is
    port(
        clk              : in  std_logic;
        -- Data in
        alu_result_in    : in  std_logic_vector(15 downto 0);
        write_data_in    : in  std_logic_vector(15 downto 0);
        dest_addr_in     : in  std_logic_vector(2 downto 0);
        flag_z_in        : in  std_logic;
        flag_n_in        : in  std_logic;
        flag_v_in        : in  std_logic;
        -- Control in (MEM + WB signals)
        reg_wr_en_in     : in  std_logic;
        mem_wr_en_in     : in  std_logic;
        mem_to_reg_in    : in  std_logic;
        io_op_in         : in  std_logic_vector(1 downto 0);
        loadimm_en_in    : in  std_logic;
        loadimm_sel_in   : in  std_logic;
        mov_en_in        : in  std_logic;
        flag_wr_en_in    : in  std_logic;
        -- Data out
        alu_result_out   : out std_logic_vector(15 downto 0);
        write_data_out   : out std_logic_vector(15 downto 0);
        dest_addr_out    : out std_logic_vector(2 downto 0);
        flag_z_out       : out std_logic;
        flag_n_out       : out std_logic;
        flag_v_out       : out std_logic;
        -- Control out
        reg_wr_en_out    : out std_logic;
        mem_wr_en_out    : out std_logic;
        mem_to_reg_out   : out std_logic;
        io_op_out        : out std_logic_vector(1 downto 0);
        loadimm_en_out   : out std_logic;
        loadimm_sel_out  : out std_logic;
        mov_en_out       : out std_logic;
        flag_wr_en_out   : out std_logic
    );
end PipeReg_EX_MEM;

architecture behavioral of PipeReg_EX_MEM is
begin
    process(clk)
    begin
        if falling_edge(clk) then
            alu_result_out  <= alu_result_in;
            write_data_out  <= write_data_in;
            dest_addr_out   <= dest_addr_in;
            flag_z_out      <= flag_z_in;
            flag_n_out      <= flag_n_in;
            flag_v_out      <= flag_v_in;
            reg_wr_en_out   <= reg_wr_en_in;
            mem_wr_en_out   <= mem_wr_en_in;
            mem_to_reg_out  <= mem_to_reg_in;
            io_op_out       <= io_op_in;
            loadimm_en_out  <= loadimm_en_in;
            loadimm_sel_out <= loadimm_sel_in;
            mov_en_out      <= mov_en_in;
            flag_wr_en_out  <= flag_wr_en_in;
        end if;
    end process;
end behavioral;


-- ============================================================================
-- MEM/WB Pipeline Register
-- Carries: memory data, ALU result, destination, and WB control
-- No stall or flush -plain latch
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity PipeReg_MEM_WB is
    port(
        clk              : in  std_logic;
        -- Data in
        mem_data_in      : in  std_logic_vector(15 downto 0);
        alu_result_in    : in  std_logic_vector(15 downto 0);
        dest_addr_in     : in  std_logic_vector(2 downto 0);
        -- Control in (WB signals)
        reg_wr_en_in     : in  std_logic;
        mem_to_reg_in    : in  std_logic;
        io_op_in         : in  std_logic_vector(1 downto 0);
        loadimm_en_in    : in  std_logic;
        loadimm_sel_in   : in  std_logic;
        mov_en_in        : in  std_logic;
        -- Data out
        mem_data_out     : out std_logic_vector(15 downto 0);
        alu_result_out   : out std_logic_vector(15 downto 0);
        dest_addr_out    : out std_logic_vector(2 downto 0);
        -- Control out
        reg_wr_en_out    : out std_logic;
        mem_to_reg_out   : out std_logic;
        io_op_out        : out std_logic_vector(1 downto 0);
        loadimm_en_out   : out std_logic;
        loadimm_sel_out  : out std_logic;
        mov_en_out       : out std_logic
    );
end PipeReg_MEM_WB;

architecture behavioral of PipeReg_MEM_WB is
begin
    process(clk)
    begin
        if falling_edge(clk) then
            mem_data_out    <= mem_data_in;
            alu_result_out  <= alu_result_in;
            dest_addr_out   <= dest_addr_in;
            reg_wr_en_out   <= reg_wr_en_in;
            mem_to_reg_out  <= mem_to_reg_in;
            io_op_out       <= io_op_in;
            loadimm_en_out  <= loadimm_en_in;
            loadimm_sel_out <= loadimm_sel_in;
            mov_en_out      <= mov_en_in;
        end if;
    end process;
end behavioral;
