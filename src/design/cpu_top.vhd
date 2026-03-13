-- ============================================================================
-- CPU_Top: 5-Stage Pipelined 16-bit CPU (FPGA Version)
-- Memory: ROM (bootloader) + XPM Distributed RAM (user programs)
-- Address decode: ROM (0x0000-0x01FF), RAM (0x0200-0x07FF), I/O (0xFFF0/FFF2)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library xpm;
use xpm.vcomponents.all;

entity CPU_Top is
    Port (
        clk         : in  STD_LOGIC;
        rst_execute : in  STD_LOGIC;
        rst_load    : in  STD_LOGIC;
        in_port     : in  STD_LOGIC_VECTOR(15 downto 0);
        out_port    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end CPU_Top;

architecture Structural of CPU_Top is

    -- =====================================================================
    -- Component Declarations
    -- =====================================================================

    component ProgramCounter is
        port(
            clk         : in  std_logic;
            rst_execute : in  std_logic;
            rst_load    : in  std_logic;
            pc_load     : in  std_logic;
            stall       : in  std_logic;
            pc_in       : in  std_logic_vector(15 downto 0);
            pc_out      : out std_logic_vector(15 downto 0)
        );
    end component;

    component Controller is
        port(
            clk         : in  std_logic;
            rst_execute : in  std_logic;
            rst_load    : in  std_logic;
            opcode      : in  std_logic_vector(6 downto 0);
            reg_wr_en   : out std_logic;
            alu_mode    : out std_logic_vector(2 downto 0);
            alu_src     : out std_logic;
            mem_wr_en   : out std_logic;
            mem_to_reg  : out std_logic;
            branch_type : out std_logic_vector(2 downto 0);
            pc_src      : out std_logic;
            io_op       : out std_logic_vector(1 downto 0);
            loadimm_en  : out std_logic;
            loadimm_sel : out std_logic;
            mov_en      : out std_logic;
            flag_wr_en  : out std_logic
        );
    end component;

    component RegisterFile is
        port(
            clk        : in  std_logic;
            wr_en      : in  std_logic;
            read_addr1 : in  std_logic_vector(2 downto 0);
            read_addr2 : in  std_logic_vector(2 downto 0);
            write_addr : in  std_logic_vector(2 downto 0);
            write_data : in  std_logic_vector(15 downto 0);
            read_data1 : out std_logic_vector(15 downto 0);
            read_data2 : out std_logic_vector(15 downto 0)
        );
    end component;

    component ALU is
        port(
            alu_mode   : in  std_logic_vector(2 downto 0);
            op1        : in  std_logic_vector(15 downto 0);
            op2        : in  std_logic_vector(15 downto 0);
            alu_result : out std_logic_vector(15 downto 0);
            flag_z     : out std_logic;
            flag_n     : out std_logic;
            flag_v     : out std_logic
        );
    end component;

    component ForwardingUnit is
        port(
            ex_src1_addr : in  std_logic_vector(2 downto 0);
            ex_src2_addr : in  std_logic_vector(2 downto 0);
            mem_rd_addr  : in  std_logic_vector(2 downto 0);
            mem_wr_en    : in  std_logic;
            wb_rd_addr   : in  std_logic_vector(2 downto 0);
            wb_wr_en     : in  std_logic;
            fwd_a        : out std_logic_vector(1 downto 0);
            fwd_b        : out std_logic_vector(1 downto 0)
        );
    end component;

    component FlagRegister is
        port(
            clk   : in  std_logic;
            wr_en : in  std_logic;
            z_in  : in  std_logic;
            n_in  : in  std_logic;
            z_out : out std_logic;
            n_out : out std_logic
        );
    end component;

    component HazardDetection is
        port(
            id_src1_addr : in  std_logic_vector(2 downto 0);
            id_src2_addr : in  std_logic_vector(2 downto 0);
            ex_rd_addr   : in  std_logic_vector(2 downto 0);
            ex_mem_read  : in  std_logic;
            branch_taken : in  std_logic;
            pc_stall     : out std_logic;
            if_id_stall  : out std_logic;
            id_ex_flush  : out std_logic;
            if_id_flush  : out std_logic
        );
    end component;

    component PipeReg_IF_ID is
        port(
            clk          : in  std_logic;
            stall        : in  std_logic;
            flush        : in  std_logic;
            instr_in     : in  std_logic_vector(15 downto 0);
            pc_plus2_in  : in  std_logic_vector(15 downto 0);
            instr_out    : out std_logic_vector(15 downto 0);
            pc_plus2_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component PipeReg_ID_EX is
        port(
            clk            : in  std_logic;
            flush          : in  std_logic;
            rd1_in         : in  std_logic_vector(15 downto 0);
            rd2_in         : in  std_logic_vector(15 downto 0);
            pc_plus2_in    : in  std_logic_vector(15 downto 0);
            imm_in         : in  std_logic_vector(15 downto 0);
            ra_in          : in  std_logic_vector(2 downto 0);
            rb_in          : in  std_logic_vector(2 downto 0);
            rc_in          : in  std_logic_vector(2 downto 0);
            src1_addr_in   : in  std_logic_vector(2 downto 0);
            src2_addr_in   : in  std_logic_vector(2 downto 0);
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
            rd1_out         : out std_logic_vector(15 downto 0);
            rd2_out         : out std_logic_vector(15 downto 0);
            pc_plus2_out    : out std_logic_vector(15 downto 0);
            imm_out         : out std_logic_vector(15 downto 0);
            ra_out          : out std_logic_vector(2 downto 0);
            rb_out          : out std_logic_vector(2 downto 0);
            rc_out          : out std_logic_vector(2 downto 0);
            src1_addr_out   : out std_logic_vector(2 downto 0);
            src2_addr_out   : out std_logic_vector(2 downto 0);
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
    end component;

    component PipeReg_EX_MEM is
        port(
            clk              : in  std_logic;
            alu_result_in    : in  std_logic_vector(15 downto 0);
            write_data_in    : in  std_logic_vector(15 downto 0);
            dest_addr_in     : in  std_logic_vector(2 downto 0);
            flag_z_in        : in  std_logic;
            flag_n_in        : in  std_logic;
            flag_v_in        : in  std_logic;
            reg_wr_en_in     : in  std_logic;
            mem_wr_en_in     : in  std_logic;
            mem_to_reg_in    : in  std_logic;
            io_op_in         : in  std_logic_vector(1 downto 0);
            loadimm_en_in    : in  std_logic;
            loadimm_sel_in   : in  std_logic;
            mov_en_in        : in  std_logic;
            flag_wr_en_in    : in  std_logic;
            alu_result_out   : out std_logic_vector(15 downto 0);
            write_data_out   : out std_logic_vector(15 downto 0);
            dest_addr_out    : out std_logic_vector(2 downto 0);
            flag_z_out       : out std_logic;
            flag_n_out       : out std_logic;
            flag_v_out       : out std_logic;
            reg_wr_en_out    : out std_logic;
            mem_wr_en_out    : out std_logic;
            mem_to_reg_out   : out std_logic;
            io_op_out        : out std_logic_vector(1 downto 0);
            loadimm_en_out   : out std_logic;
            loadimm_sel_out  : out std_logic;
            mov_en_out       : out std_logic;
            flag_wr_en_out   : out std_logic
        );
    end component;

    component PipeReg_MEM_WB is
        port(
            clk              : in  std_logic;
            mem_data_in      : in  std_logic_vector(15 downto 0);
            alu_result_in    : in  std_logic_vector(15 downto 0);
            dest_addr_in     : in  std_logic_vector(2 downto 0);
            reg_wr_en_in     : in  std_logic;
            mem_to_reg_in    : in  std_logic;
            io_op_in         : in  std_logic_vector(1 downto 0);
            loadimm_en_in    : in  std_logic;
            loadimm_sel_in   : in  std_logic;
            mov_en_in        : in  std_logic;
            mem_data_out     : out std_logic_vector(15 downto 0);
            alu_result_out   : out std_logic_vector(15 downto 0);
            dest_addr_out    : out std_logic_vector(2 downto 0);
            reg_wr_en_out    : out std_logic;
            mem_to_reg_out   : out std_logic;
            io_op_out        : out std_logic_vector(1 downto 0);
            loadimm_en_out   : out std_logic;
            loadimm_sel_out  : out std_logic;
            mov_en_out       : out std_logic
        );
    end component;

    -- =====================================================================
    -- Internal Signals
    -- =====================================================================

    -- ---- IF Stage ----
    signal pc_current     : std_logic_vector(15 downto 0);
    signal pc_plus2_if    : std_logic_vector(15 downto 0);
    signal if_instruction : std_logic_vector(15 downto 0);

    -- ---- Memory signals ----
    -- ROM: bootloader at 0x0000-0x01FF (256 words, initialized from .coe)
    -- RAM: user programs at 0x0200+ (512 words via XPM)
    -- I/O: 0xFFF0 = in_port read, 0xFFF2 = out_port write
    signal rom_data       : std_logic_vector(15 downto 0);
    signal ram_data_portA : std_logic_vector(15 downto 0);
    signal ram_data_portB : std_logic_vector(15 downto 0);
    signal ram_wr_en_vec  : std_logic_vector(0 downto 0);
    signal mem_read_portB : std_logic_vector(15 downto 0) := (others => '0');
    signal is_rom_fetch   : std_logic;
    signal is_ram_data    : std_logic;
    signal is_io_read     : std_logic;
    signal is_io_write    : std_logic;

    -- ---- IF/ID outputs ----
    signal ifid_instr    : std_logic_vector(15 downto 0);
    signal ifid_pc_plus2 : std_logic_vector(15 downto 0);

    -- ---- ID Stage ----
    signal id_opcode : std_logic_vector(6 downto 0);
    signal id_ra     : std_logic_vector(2 downto 0);
    signal id_rb     : std_logic_vector(2 downto 0);
    signal id_rc     : std_logic_vector(2 downto 0);
    signal id_imm    : std_logic_vector(15 downto 0);

    -- Controller outputs (ID stage)
    signal ctrl_reg_wr_en   : std_logic;
    signal ctrl_alu_mode    : std_logic_vector(2 downto 0);
    signal ctrl_alu_src     : std_logic;
    signal ctrl_mem_wr_en   : std_logic;
    signal ctrl_mem_to_reg  : std_logic;
    signal ctrl_branch_type : std_logic_vector(2 downto 0);
    signal ctrl_pc_src      : std_logic;
    signal ctrl_io_op       : std_logic_vector(1 downto 0);
    signal ctrl_loadimm_en  : std_logic;
    signal ctrl_loadimm_sel : std_logic;
    signal id_loadimm_sel   : std_logic;
    signal ctrl_mov_en      : std_logic;
    signal ctrl_flag_wr_en  : std_logic;

    -- Register File read outputs (ID stage)
    signal rf_read_data1 : std_logic_vector(15 downto 0);
    signal rf_read_data2 : std_logic_vector(15 downto 0);

    -- Register File read addresses (muxed for special instructions)
    signal rf_read_addr1 : std_logic_vector(2 downto 0);
    signal rf_read_addr2 : std_logic_vector(2 downto 0);

    -- ---- ID/EX outputs ----
    signal idex_rd1         : std_logic_vector(15 downto 0);
    signal idex_rd2         : std_logic_vector(15 downto 0);
    signal idex_pc_plus2    : std_logic_vector(15 downto 0);
    signal idex_imm         : std_logic_vector(15 downto 0);
    signal idex_ra          : std_logic_vector(2 downto 0);
    signal idex_rb          : std_logic_vector(2 downto 0);
    signal idex_rc          : std_logic_vector(2 downto 0);
    signal idex_reg_wr_en   : std_logic;
    signal idex_alu_mode    : std_logic_vector(2 downto 0);
    signal idex_alu_src     : std_logic;
    signal idex_mem_wr_en   : std_logic;
    signal idex_mem_to_reg  : std_logic;
    signal idex_branch_type : std_logic_vector(2 downto 0);
    signal idex_io_op       : std_logic_vector(1 downto 0);
    signal idex_loadimm_en  : std_logic;
    signal idex_loadimm_sel : std_logic;
    signal idex_mov_en      : std_logic;
    signal idex_flag_wr_en  : std_logic;

    -- ---- ID/EX source address outputs (for forwarding) ----
    signal idex_src1_addr : std_logic_vector(2 downto 0);
    signal idex_src2_addr : std_logic_vector(2 downto 0);

    -- ---- EX Stage ----
    signal alu_op1      : std_logic_vector(15 downto 0);
    signal alu_op2      : std_logic_vector(15 downto 0);
    signal alu_result   : std_logic_vector(15 downto 0);
    signal alu_flag_z   : std_logic;
    signal alu_flag_n   : std_logic;
    signal alu_flag_v   : std_logic;
    signal ex_result    : std_logic_vector(15 downto 0);
    signal ex_write_data : std_logic_vector(15 downto 0);

    -- Forwarding mux selects and forwarded data
    signal fwd_a_sel    : std_logic_vector(1 downto 0);
    signal fwd_b_sel    : std_logic_vector(1 downto 0);
    signal fwd_data_a   : std_logic_vector(15 downto 0);
    signal fwd_data_b   : std_logic_vector(15 downto 0);

    -- Branch logic signals (EX stage)
    signal branch_target   : std_logic_vector(15 downto 0);
    signal branch_taken    : std_logic;
    signal branch_base     : std_logic_vector(15 downto 0);
    signal branch_offset   : std_logic_vector(15 downto 0);
    signal is_brr_type     : std_logic;  -- BRR/BRR.N/BRR.Z (PC-relative)

    -- EX/MEM dest address (muxed for BR.SUB -> r7)
    signal ex_dest_addr    : std_logic_vector(2 downto 0);

    -- ---- EX/MEM outputs ----
    signal exmem_alu_result  : std_logic_vector(15 downto 0);
    signal exmem_write_data  : std_logic_vector(15 downto 0);
    signal exmem_dest_addr   : std_logic_vector(2 downto 0);
    signal exmem_flag_z      : std_logic;
    signal exmem_flag_n      : std_logic;
    signal exmem_reg_wr_en   : std_logic;
    signal exmem_mem_wr_en   : std_logic;
    signal exmem_mem_to_reg  : std_logic;
    signal exmem_io_op       : std_logic_vector(1 downto 0);
    signal exmem_loadimm_en  : std_logic;
    signal exmem_loadimm_sel : std_logic;
    signal exmem_mov_en      : std_logic;
    signal exmem_flag_wr_en  : std_logic;
    signal exmem_flag_v      : std_logic;

    -- ---- MEM Stage ----
    signal mem_read_data  : std_logic_vector(15 downto 0);

    -- ---- MEM/WB outputs ----
    signal memwb_mem_data    : std_logic_vector(15 downto 0);
    signal memwb_alu_result  : std_logic_vector(15 downto 0);
    signal memwb_dest_addr   : std_logic_vector(2 downto 0);
    signal memwb_reg_wr_en   : std_logic;
    signal memwb_mem_to_reg  : std_logic;
    signal memwb_io_op       : std_logic_vector(1 downto 0);
    signal memwb_loadimm_en  : std_logic;
    signal memwb_loadimm_sel : std_logic;
    signal memwb_mov_en      : std_logic;

    -- ---- WB Stage ----
    signal wb_data       : std_logic_vector(15 downto 0);
    signal wb_write_addr : std_logic_vector(2 downto 0);
    signal wb_wr_en      : std_logic;

    -- ---- Output Register ----
    signal out_port_reg : std_logic_vector(15 downto 0) := (others => '0');

    -- ---- Hazard/branch control ----
    signal pc_stall      : std_logic;
    signal ifid_stall    : std_logic;
    signal ifid_flush    : std_logic;
    signal idex_flush    : std_logic;
    signal hz_pc_stall   : std_logic;
    signal hz_ifid_stall : std_logic;
    signal hz_idex_flush : std_logic;
    signal hz_ifid_flush : std_logic;
    signal pc_load_sig   : std_logic;
    signal pc_in_sig     : std_logic_vector(15 downto 0);

    -- Flag register outputs
    signal flag_z_out : std_logic;
    signal flag_n_out : std_logic;

    -- Flag write enable (pipeline-tracked)
    signal flag_wr_en_pipe : std_logic;

    -- Effective register file write signals (merges WB + BR.SUB r7 write)
    signal rf_wr_en_eff   : std_logic;
    signal rf_wr_addr_eff : std_logic_vector(2 downto 0);
    signal rf_wr_data_eff : std_logic_vector(15 downto 0);

begin

    -- =====================================================================
    -- STAGE 1: INSTRUCTION FETCH (IF)
    -- =====================================================================

    PC_Unit: ProgramCounter port map (
        clk         => clk,
        rst_execute => rst_execute,
        rst_load    => rst_load,
        pc_load     => pc_load_sig,
        stall       => pc_stall,
        pc_in       => pc_in_sig,
        pc_out      => pc_current
    );

    pc_plus2_if <= std_logic_vector(unsigned(pc_current) + 2);

    -- =====================================================================
    -- ROM: Bootloader (256 words, initialized from bootloader.coe)
    -- Port B of XPM used for instruction fetch when PC < 0x0200
    -- =====================================================================
    -- ROM select: PC[9] = '0' means ROM space (0x0000-0x01FF)
    is_rom_fetch <= '1' when pc_current(9) = '0' else '0';

    ROM_inst : xpm_memory_sprom
    generic map (
        ADDR_WIDTH_A        => 8,
        AUTO_SLEEP_TIME     => 0,
        ECC_MODE            => "no_ecc",
        MEMORY_INIT_FILE    => "program.mem",  -- your assembled program (see README)
        MEMORY_INIT_PARAM   => "",
        MEMORY_OPTIMIZATION => "true",
        MEMORY_PRIMITIVE     => "auto",
        MEMORY_SIZE          => 4096,    -- 256 words x 16 bits
        MESSAGE_CONTROL      => 0,
        READ_DATA_WIDTH_A    => 16,
        READ_LATENCY_A       => 1,
        READ_RESET_VALUE_A   => "0",
        RST_MODE_A           => "SYNC",
        SIM_ASSERT_CHK       => 0,
        USE_MEM_INIT         => 1,
        USE_MEM_INIT_MMI     => 0,
        WAKEUP_TIME          => "disable_sleep"
    )
    port map (
        clka    => clk,
        rsta    => '0',
        ena     => '1',
        regcea  => '1',
        addra   => pc_current(8 downto 1),
        douta   => rom_data,
        injectsbiterra => '0',
        injectdbiterra => '0',
        sbiterra => open,
        dbiterra => open,
        sleep    => '0'
    );

    -- =====================================================================
    -- RAM: User programs + data (512 words via XPM)
    -- Port A: MEM stage read/write (data access)
    -- Port B: IF stage read (instruction fetch when PC >= 0x0200)
    -- =====================================================================
    ram_wr_en_vec(0) <= exmem_mem_wr_en and is_ram_data;

    RAM_inst : xpm_memory_dpdistram
    generic map (
        ADDR_WIDTH_A       => 9,
        ADDR_WIDTH_B       => 9,
        BYTE_WRITE_WIDTH_A => 16,
        CLOCKING_MODE      => "common_clock",
        MEMORY_INIT_FILE   => "none",
        MEMORY_INIT_PARAM  => "",
        MEMORY_OPTIMIZATION => "true",
        MEMORY_SIZE         => 8192,    -- 512 words x 16 bits
        READ_DATA_WIDTH_A   => 16,
        READ_DATA_WIDTH_B   => 16,
        READ_LATENCY_A      => 1,
        READ_LATENCY_B      => 1,
        READ_RESET_VALUE_A  => "0",
        READ_RESET_VALUE_B  => "0",
        USE_EMBEDDED_CONSTRAINT => 0,
        USE_MEM_INIT        => 0,
        USE_MEM_INIT_MMI    => 0,
        WRITE_DATA_WIDTH_A  => 16
    )
    port map (
        clka   => clk,
        rsta   => '0',
        ena    => '1',
        regcea => '1',
        wea    => ram_wr_en_vec,
        addra  => exmem_alu_result(9 downto 1),
        dina   => exmem_write_data,
        douta  => ram_data_portA,
        clkb   => clk,
        rstb   => '0',
        enb    => '1',
        regceb => '1',
        addrb  => pc_current(9 downto 1),
        doutb  => ram_data_portB
    );

    -- Instruction fetch mux: ROM or RAM based on PC[9]
    if_instruction <= rom_data when is_rom_fetch = '1' else ram_data_portB;

    -- IF/ID Pipeline Register
    IFID: PipeReg_IF_ID port map (
        clk          => clk,
        stall        => ifid_stall,
        flush        => ifid_flush,
        instr_in     => if_instruction,
        pc_plus2_in  => pc_plus2_if,
        instr_out    => ifid_instr,
        pc_plus2_out => ifid_pc_plus2
    );

    -- =====================================================================
    -- STAGE 2: INSTRUCTION DECODE (ID)
    -- =====================================================================

    -- Instruction field extraction
    id_opcode <= ifid_instr(15 downto 9);
    id_ra     <= ifid_instr(8 downto 6);
    id_rb     <= ifid_instr(5 downto 3);
    id_rc     <= ifid_instr(2 downto 0);

    -- Immediate field mux:
    --   Format A2 (SHL/SHR): zero-extend c1[2:0]
    --   Format B1 (BRR*): sign-extend disp.l[8:0], then shift left 1
    --   Format B2 (BR*): sign-extend disp.s[5:0], then shift left 1
    -- Section 9.4: sign-extend FIRST, then multiply by 2 (shift left 1)
    -- We compute the scaled displacement here so it's ready in EX stage.
    -- For non-branch instructions, this field is just c1 zero-extended.
    imm_mux: process(ifid_instr, ctrl_branch_type, ctrl_alu_src, ctrl_loadimm_en)
        variable disp_l_ext : signed(15 downto 0);
        variable disp_s_ext : signed(15 downto 0);
    begin
        if ctrl_loadimm_en = '1' then
            -- LOADIMM (L1): zero-extend imm[7:0]
            id_imm <= x"00" & ifid_instr(7 downto 0);
        elsif ctrl_branch_type = "001" or ctrl_branch_type = "010" or
              ctrl_branch_type = "011" then
            -- BRR / BRR.N / BRR.Z: sign-extend disp.l[8:0], shift left 1
            disp_l_ext := resize(signed(ifid_instr(8 downto 0)), 16);
            id_imm <= std_logic_vector(shift_left(disp_l_ext, 1));
        elsif ctrl_branch_type = "100" or ctrl_branch_type = "101" or
              ctrl_branch_type = "110" or ctrl_branch_type = "111" then
            -- BR / BR.N / BR.Z / BR.SUB: sign-extend disp.s[5:0], shift left 1
            disp_s_ext := resize(signed(ifid_instr(5 downto 0)), 16);
            id_imm <= std_logic_vector(shift_left(disp_s_ext, 1));
        else
            -- Format A: zero-extend c1[2:0]
            id_imm <= "0000000000000" & ifid_instr(2 downto 0);
        end if;
    end process;

    -- Controller (combinational decode)
    ControlUnit: Controller port map (
        clk         => clk,
        rst_execute => rst_execute,
        rst_load    => rst_load,
        opcode      => id_opcode,
        reg_wr_en   => ctrl_reg_wr_en,
        alu_mode    => ctrl_alu_mode,
        alu_src     => ctrl_alu_src,
        mem_wr_en   => ctrl_mem_wr_en,
        mem_to_reg  => ctrl_mem_to_reg,
        branch_type => ctrl_branch_type,
        pc_src      => ctrl_pc_src,
        io_op       => ctrl_io_op,
        loadimm_en  => ctrl_loadimm_en,
        loadimm_sel => ctrl_loadimm_sel,
        mov_en      => ctrl_mov_en,
        flag_wr_en  => ctrl_flag_wr_en
    );

    -- Register File read address muxing:
    --   NAND/SHL/SHR/TEST/OUT: read port 1 = R[ra]
    --   BR/BR.N/BR.Z/BR.SUB: read port 1 = R[ra] (base address)
    --   RETURN: read port 1 = R[r7] (opcode forces ra read to r7)
    --   ADD/SUB/MUL: read port 1 = R[rb], read port 2 = R[rc]
    rf_read_addr1 <= "111" when (id_opcode = "1000111" or  -- RETURN: force r7
                                  ctrl_loadimm_en = '1')   -- LOADIMM: read r7 for merge
                     else id_ra when (ctrl_alu_src = '1' or
                                      ctrl_alu_mode = "111" or
                                      ctrl_io_op = "10" or
                                      ctrl_branch_type(2) = '1')  -- BR variants
                     else id_rb;

    rf_read_addr2 <= id_rb when (ctrl_mem_wr_en = '1')
                     else id_rc;

    -- LOADIMM sel mux: use instruction bit 8 for LOADIMM, controller output for others
    id_loadimm_sel <= ifid_instr(8) when ctrl_loadimm_en = '1' else ctrl_loadimm_sel;

    -- Register File
    RegFile: RegisterFile port map (
        clk        => clk,
        wr_en      => rf_wr_en_eff,
        read_addr1 => rf_read_addr1,
        read_addr2 => rf_read_addr2,
        write_addr => rf_wr_addr_eff,
        write_data => rf_wr_data_eff,
        read_data1 => rf_read_data1,
        read_data2 => rf_read_data2
    );

    -- Hazard Detection Unit: detects load-use hazards
    -- Compares ID-stage source registers with EX-stage LOAD destination
    HazardUnit: HazardDetection port map (
        id_src1_addr => rf_read_addr1,
        id_src2_addr => rf_read_addr2,
        ex_rd_addr   => idex_ra,
        ex_mem_read  => idex_mem_to_reg,
        branch_taken => branch_taken,
        pc_stall     => hz_pc_stall,
        if_id_stall  => hz_ifid_stall,
        id_ex_flush  => hz_idex_flush,
        if_id_flush  => hz_ifid_flush
    );

    -- Combine hazard and branch control signals
    pc_stall   <= hz_pc_stall;
    ifid_stall <= hz_ifid_stall;
    idex_flush <= hz_idex_flush;
    ifid_flush <= hz_ifid_flush;

    -- ID/EX Pipeline Register
    IDEX: PipeReg_ID_EX port map (
        clk            => clk,
        flush          => idex_flush,
        rd1_in         => rf_read_data1,
        rd2_in         => rf_read_data2,
        pc_plus2_in    => ifid_pc_plus2,
        imm_in         => id_imm,
        ra_in          => id_ra,
        rb_in          => id_rb,
        rc_in          => id_rc,
        src1_addr_in   => rf_read_addr1,
        src2_addr_in   => rf_read_addr2,
        reg_wr_en_in   => ctrl_reg_wr_en,
        alu_mode_in    => ctrl_alu_mode,
        alu_src_in     => ctrl_alu_src,
        mem_wr_en_in   => ctrl_mem_wr_en,
        mem_to_reg_in  => ctrl_mem_to_reg,
        branch_type_in => ctrl_branch_type,
        io_op_in       => ctrl_io_op,
        loadimm_en_in  => ctrl_loadimm_en,
        loadimm_sel_in => id_loadimm_sel,
        mov_en_in      => ctrl_mov_en,
        flag_wr_en_in  => ctrl_flag_wr_en,
        rd1_out         => idex_rd1,
        rd2_out         => idex_rd2,
        pc_plus2_out    => idex_pc_plus2,
        imm_out         => idex_imm,
        ra_out          => idex_ra,
        rb_out          => idex_rb,
        rc_out          => idex_rc,
        src1_addr_out   => idex_src1_addr,
        src2_addr_out   => idex_src2_addr,
        reg_wr_en_out   => idex_reg_wr_en,
        alu_mode_out    => idex_alu_mode,
        alu_src_out     => idex_alu_src,
        mem_wr_en_out   => idex_mem_wr_en,
        mem_to_reg_out  => idex_mem_to_reg,
        branch_type_out => idex_branch_type,
        io_op_out       => idex_io_op,
        loadimm_en_out  => idex_loadimm_en,
        loadimm_sel_out => idex_loadimm_sel,
        mov_en_out      => idex_mov_en,
        flag_wr_en_out  => idex_flag_wr_en
    );

    -- =====================================================================
    -- STAGE 3: EXECUTE (EX) - with Forwarding + Branch Logic
    -- =====================================================================

    -- Forwarding Unit: detects RAW hazards and selects bypass paths
    FwdUnit: ForwardingUnit port map (
        ex_src1_addr => idex_src1_addr,
        ex_src2_addr => idex_src2_addr,
        mem_rd_addr  => exmem_dest_addr,
        mem_wr_en    => exmem_reg_wr_en,
        wb_rd_addr   => memwb_dest_addr,
        wb_wr_en     => memwb_reg_wr_en,
        fwd_a        => fwd_a_sel,
        fwd_b        => fwd_b_sel
    );

    -- Forwarding mux A: select operand 1 source
    fwd_data_a <= idex_rd1         when fwd_a_sel = "00"
                  else exmem_alu_result when fwd_a_sel = "01"
                  else wb_data          when fwd_a_sel = "10"
                  else idex_rd1;

    -- Forwarding mux B: select operand 2 source
    fwd_data_b <= idex_rd2         when fwd_b_sel = "00"
                  else exmem_alu_result when fwd_b_sel = "01"
                  else wb_data          when fwd_b_sel = "10"
                  else idex_rd2;

    -- ALU operand 1: forwarded data A
    alu_op1 <= fwd_data_a;

    -- ALU operand 2: forwarded data B or immediate (for SHL/SHR)
    alu_op2 <= idex_imm when idex_alu_src = '1'
               else fwd_data_b;

    -- ALU
    ExecutionUnit: ALU port map (
        alu_mode   => idex_alu_mode,
        op1        => alu_op1,
        op2        => alu_op2,
        alu_result => alu_result,
        flag_z     => alu_flag_z,
        flag_n     => alu_flag_n,
        flag_v     => alu_flag_v
    );

    -- ---- Branch Target Computation (EX stage) ----
    -- BRR types (001,010,011): base = PC of the branch instruction
    --   PC of the branch = idex_pc_plus2 - 2
    -- BR types (100,101,110,111): base = R[ra] (forwarded via fwd_data_a)
    -- RETURN uses branch_type=100 with ra forced to r7 in ID stage
    is_brr_type <= '1' when (idex_branch_type = "001" or
                             idex_branch_type = "010" or
                             idex_branch_type = "011") else '0';

    -- For BRR: base = PC_of_branch = idex_pc_plus2 - 2
    -- For BR/RETURN: base = R[ra] (already in fwd_data_a)
    branch_base <= std_logic_vector(unsigned(idex_pc_plus2) - 2) when is_brr_type = '1'
                   else fwd_data_a;

    -- idex_imm already contains the scaled displacement (sign-ext << 1)
    -- For RETURN (branch_type=100), idex_imm=0 since displacement bits are 0 in A0 format
    branch_offset <= idex_imm;

    -- Branch target = base + scaled_displacement
    branch_target <= std_logic_vector(unsigned(branch_base) + unsigned(branch_offset));

    -- Branch condition evaluation with flag forwarding.
    -- If a TEST in EX/MEM has flag_wr_en=1, use its flags (exmem_flag_z/n)
    -- instead of the committed FlagRegister (which is 1 cycle stale).
    branch_eval: process(idex_branch_type, flag_z_out, flag_n_out,
                         exmem_flag_wr_en, exmem_flag_z, exmem_flag_n,
                         idex_loadimm_sel, exmem_flag_v)
        variable eff_z : std_logic;
        variable eff_n : std_logic;
    begin
        if exmem_flag_wr_en = '1' then
            eff_z := exmem_flag_z;
            eff_n := exmem_flag_n;
        else
            eff_z := flag_z_out;
            eff_n := flag_n_out;
        end if;

        branch_taken <= '0';
        case idex_branch_type is
            when "001" =>  -- BRR (unconditional)
                branch_taken <= '1';
            when "010" =>  -- BRR.N (if N=1) or BRR.overflow (if V=1)
                if idex_loadimm_sel = '1' then
                    branch_taken <= exmem_flag_v;  -- BRR.overflow: check MUL overflow
                else
                    branch_taken <= eff_n;  -- BRR.N: check negative flag
                end if;
            when "011" =>  -- BRR.Z (if Z=1)
                branch_taken <= eff_z;
            when "100" =>  -- BR / RETURN (unconditional)
                branch_taken <= '1';
            when "101" =>  -- BR.N (if N=1)
                branch_taken <= eff_n;
            when "110" =>  -- BR.Z (if Z=1)
                branch_taken <= eff_z;
            when "111" =>  -- BR.SUB (unconditional)
                branch_taken <= '1';
            when others =>  -- "000" = no branch
                branch_taken <= '0';
        end case;
    end process;

    -- PC control: load branch target when branch is taken
    pc_load_sig <= branch_taken;
    pc_in_sig   <= branch_target;

    -- EX result mux:
    --   IN  (io_op=01): pass in_port directly to writeback path
    --   OUT (io_op=10): pass forwarded R[ra] so register value reaches MEM stage
    --   BR.SUB (branch_type=111): pass PC+2 so it writes to r7 via normal WB path
    --   LOAD/STORE (mem_to_reg=1 or mem_wr_en=1): pass address from fwd_data_a
    --   MOV (mov_en=1): pass R[r.src] from fwd_data_a
    --   Otherwise: ALU result
    -- LOADIMM byte merge: combine 8-bit immediate with R7's current value
    -- fwd_data_a = forwarded R7, idex_imm[7:0] = immediate byte
    -- idex_loadimm_sel: '1'=upper byte, '0'=lower byte
    ex_result <= in_port        when idex_io_op = "01"
                 else fwd_data_a   when idex_io_op = "10"
                 else idex_pc_plus2 when idex_branch_type = "111"
                 else fwd_data_a   when (idex_mem_to_reg = '1' or idex_mem_wr_en = '1'
                                         or idex_mov_en = '1')
                 else (idex_imm(7 downto 0) & fwd_data_a(7 downto 0))
                      when (idex_loadimm_en = '1' and idex_loadimm_sel = '1')
                 else (fwd_data_a(15 downto 8) & idex_imm(7 downto 0))
                      when (idex_loadimm_en = '1' and idex_loadimm_sel = '0')
                 else alu_result;

    -- Write data for MEM stage (STORE uses rd2, apply forwarding)
    ex_write_data <= fwd_data_b;

    -- For BR.SUB: dest_addr must be r7 ("111") so the return address
    -- goes through the normal WB pipeline to write r7
    ex_dest_addr <= "111" when (idex_branch_type = "111" or idex_loadimm_en = '1')
                    else idex_ra;

    -- EX/MEM Pipeline Register
    EXMEM: PipeReg_EX_MEM port map (
        clk              => clk,
        alu_result_in    => ex_result,
        write_data_in    => ex_write_data,
        dest_addr_in     => ex_dest_addr,
        flag_z_in        => alu_flag_z,
        flag_n_in        => alu_flag_n,
        flag_v_in        => alu_flag_v,
        reg_wr_en_in     => idex_reg_wr_en,
        mem_wr_en_in     => idex_mem_wr_en,
        mem_to_reg_in    => idex_mem_to_reg,
        io_op_in         => idex_io_op,
        loadimm_en_in    => idex_loadimm_en,
        loadimm_sel_in   => idex_loadimm_sel,
        mov_en_in        => idex_mov_en,
        flag_wr_en_in    => idex_flag_wr_en,
        alu_result_out   => exmem_alu_result,
        write_data_out   => exmem_write_data,
        dest_addr_out    => exmem_dest_addr,
        flag_z_out       => exmem_flag_z,
        flag_n_out       => exmem_flag_n,
        flag_v_out       => exmem_flag_v,
        reg_wr_en_out    => exmem_reg_wr_en,
        mem_wr_en_out    => exmem_mem_wr_en,
        mem_to_reg_out   => exmem_mem_to_reg,
        io_op_out        => exmem_io_op,
        loadimm_en_out   => exmem_loadimm_en,
        loadimm_sel_out  => exmem_loadimm_sel,
        mov_en_out       => exmem_mov_en,
        flag_wr_en_out   => exmem_flag_wr_en
    );

    -- =====================================================================
    -- STAGE 4: MEMORY ACCESS (MEM)
    -- =====================================================================

    -- =====================================================================
    -- MEM stage address decode
    -- RAM:  0x0200-0x07FF (addresses with bits[15:10] = 000000, bit[9]=1)
    -- I/O:  0xFFF0 = in_port read, 0xFFF2 = out_port write
    -- ROM:  0x0000-0x01FF (read-only, not accessed via LOAD/STORE normally)
    -- =====================================================================
    is_ram_data <= '1' when unsigned(exmem_alu_result) < x"FFF0" else '0';
    is_io_read  <= '1' when exmem_alu_result = x"FFF0" else '0';
    is_io_write <= '1' when exmem_alu_result = x"FFF2" and exmem_mem_wr_en = '1' else '0';

    -- RAM write is handled by ram_wr_en_vec above (in RAM_inst port map)
    -- RAM read data comes from ram_data_portA (1-cycle latency via XPM)

    -- Memory read data mux: RAM, I/O, or zero
    mem_read_data <= in_port       when is_io_read = '1'
                     else ram_data_portA;

    -- Flag Register: updated when TEST instruction reaches MEM stage
    -- flag_wr_en propagates through ID/EX -> EX/MEM pipeline
    flag_wr_en_pipe <= exmem_flag_wr_en;

    FlagReg: FlagRegister port map (
        clk   => clk,
        wr_en => flag_wr_en_pipe,
        z_in  => exmem_flag_z,
        n_in  => exmem_flag_n,
        z_out => flag_z_out,
        n_out => flag_n_out
    );

    -- OUT instruction + memory-mapped I/O write to 0xFFF2
    out_proc: process(clk)
    begin
        if falling_edge(clk) then
            if exmem_io_op = "10" then
                out_port_reg <= exmem_alu_result;
            elsif is_io_write = '1' then
                out_port_reg <= exmem_write_data;
            end if;
        end if;
    end process;

    out_port <= out_port_reg;

    -- MEM/WB Pipeline Register
    MEMWB: PipeReg_MEM_WB port map (
        clk              => clk,
        mem_data_in      => mem_read_data,
        alu_result_in    => exmem_alu_result,
        dest_addr_in     => exmem_dest_addr,
        reg_wr_en_in     => exmem_reg_wr_en,
        mem_to_reg_in    => exmem_mem_to_reg,
        io_op_in         => exmem_io_op,
        loadimm_en_in    => exmem_loadimm_en,
        loadimm_sel_in   => exmem_loadimm_sel,
        mov_en_in        => exmem_mov_en,
        mem_data_out     => memwb_mem_data,
        alu_result_out   => memwb_alu_result,
        dest_addr_out    => memwb_dest_addr,
        reg_wr_en_out    => memwb_reg_wr_en,
        mem_to_reg_out   => memwb_mem_to_reg,
        io_op_out        => memwb_io_op,
        loadimm_en_out   => memwb_loadimm_en,
        loadimm_sel_out  => memwb_loadimm_sel,
        mov_en_out       => memwb_mov_en
    );

    -- =====================================================================
    -- STAGE 5: WRITE BACK (WB)
    -- =====================================================================

    wb_data <= memwb_mem_data when memwb_mem_to_reg = '1'
               else memwb_alu_result;

    wb_write_addr <= memwb_dest_addr;
    wb_wr_en      <= memwb_reg_wr_en;

    -- Effective register file write: merges normal WB path
    -- BR.SUB's r7 write now flows through the normal WB pipeline
    -- (dest_addr forced to "111", ex_result set to PC+2)
    -- so no separate write port is needed.
    rf_wr_en_eff   <= wb_wr_en;
    rf_wr_addr_eff <= wb_write_addr;
    rf_wr_data_eff <= wb_data;

end Structural;
