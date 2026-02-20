library ieee;
use ieee.std_logic_1164.all;

entity Controller is
    port(
        clk         : in  std_logic;
        rst_execute : in  std_logic;
        rst_load    : in  std_logic;
        opcode      : in  std_logic_vector(6 downto 0);
        -- Control outputs
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
end Controller;

-- branch_type encoding:
--   "000" = no branch
--   "001" = BRR  (unconditional, PC-relative)
--   "010" = BRR.N (conditional N=1, PC-relative)
--   "011" = BRR.Z (conditional Z=1, PC-relative)
--   "100" = BR / RETURN (unconditional, register-relative)
--   "101" = BR.N (conditional N=1, register-relative)
--   "110" = BR.Z (conditional Z=1, register-relative)
--   "111" = BR.SUB (unconditional, register-relative, link r7)
--
-- For RETURN: branch_type="100", datapath forces ra read to r7 ("111")
--
-- loadimm_sel: always '0' from controller. The actual m.l bit is routed
-- from instruction[8] in the ID stage datapath, since the controller
-- only receives the 7-bit opcode.

architecture behavioral of Controller is

    type state_type is (RESET_STATE, ACTIVE_STATE);
    signal current_state : state_type := RESET_STATE;

begin

    -- Clocked FSM for reset sequencing
    fsm_proc: process(clk)
    begin
        if falling_edge(clk) then
            if rst_execute = '1' or rst_load = '1' then
                current_state <= RESET_STATE;
            else
                case current_state is
                    when RESET_STATE =>
                        current_state <= ACTIVE_STATE;
                    when ACTIVE_STATE =>
                        current_state <= ACTIVE_STATE;
                    when others =>
                        current_state <= RESET_STATE;
                end case;
            end if;
        end if;
    end process;

    -- Combinational decode (gated by FSM state)
    decode_proc: process(current_state, opcode)
    begin
        -- Safe defaults: NOP bubble (no writes, no branches)
        reg_wr_en   <= '0';
        alu_mode    <= "000";
        alu_src     <= '0';
        mem_wr_en   <= '0';
        mem_to_reg  <= '0';
        branch_type <= "000";
        pc_src      <= '0';
        io_op       <= "00";
        loadimm_en  <= '0';
        loadimm_sel <= '0';
        mov_en      <= '0';
        flag_wr_en  <= '0';

        if current_state = ACTIVE_STATE then
            case opcode is

                -- =============================================================
                -- FORMAT A: Arithmetic / Logic / I/O
                -- =============================================================

                -- NOP (opcode 0) - all defaults, nothing to do
                when "0000000" =>
                    null;

                -- ADD (opcode 1): R[ra] <- R[rb] + R[rc]
                when "0000001" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "001";

                -- SUB (opcode 2): R[ra] <- R[rb] - R[rc]
                when "0000010" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "010";

                -- MUL (opcode 3): R[ra] <- R[rb] x R[rc]
                when "0000011" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "011";

                -- NAND (opcode 4): R[ra] <- R[ra] NAND R[rb]
                -- Datapath routes op1=R[ra], op2=R[rb] (Section 9.2)
                when "0000100" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "100";

                -- SHL (opcode 5): R[ra] << c1
                -- alu_src=1: op2 from immediate field c1, not register
                -- Datapath routes op1=R[ra] (Section 9.3)
                when "0000101" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "101";
                    alu_src   <= '1';

                -- SHR (opcode 6): R[ra] >> c1
                -- alu_src=1: op2 from immediate field c1, not register
                -- Datapath routes op1=R[ra] (Section 9.3)
                when "0000110" =>
                    reg_wr_en <= '1';
                    alu_mode  <= "110";
                    alu_src   <= '1';

                -- TEST (opcode 7): set Z/N flags from R[ra], no register writeback
                when "0000111" =>
                    alu_mode   <= "111";
                    flag_wr_en <= '1';

                -- OUT (opcode 32): OUT_PORT <- R[ra]
                when "0100000" =>
                    io_op <= "10";

                -- IN (opcode 33): R[ra] <- IN_PORT
                when "0100001" =>
                    reg_wr_en <= '1';
                    io_op     <= "01";

                -- =============================================================
                -- FORMAT B: Branches
                -- =============================================================

                -- BRR (opcode 64): PC <- PC + 2*disp.l (unconditional)
                when "1000000" =>
                    branch_type <= "001";
                    pc_src      <= '1';

                -- BRR.N (opcode 65): if N=1 then branch
                when "1000001" =>
                    branch_type <= "010";
                    pc_src      <= '1';

                -- BRR.Z (opcode 66): if Z=1 then branch
                when "1000010" =>
                    branch_type <= "011";
                    pc_src      <= '1';

                -- BR (opcode 67): PC <- R[ra] + 2*disp.s (unconditional)
                when "1000011" =>
                    branch_type <= "100";
                    pc_src      <= '1';

                -- BR.N (opcode 68): if N=1 then PC <- R[ra] + 2*disp.s
                when "1000100" =>
                    branch_type <= "101";
                    pc_src      <= '1';

                -- BR.Z (opcode 69): if Z=1 then PC <- R[ra] + 2*disp.s
                when "1000101" =>
                    branch_type <= "110";
                    pc_src      <= '1';

                -- BR.SUB (opcode 70): r7 <- PC+2; PC <- R[ra] + 2*disp.s
                -- reg_wr_en=1: writes return address to r7
                when "1000110" =>
                    reg_wr_en   <= '1';
                    branch_type <= "111";
                    pc_src      <= '1';

                -- RETURN (opcode 71): PC <- r7
                -- Uses branch_type="100" (same as BR unconditional)
                -- Datapath overrides ra to "111" (r7) for this opcode
                when "1000111" =>
                    branch_type <= "100";
                    pc_src      <= '1';

                -- BRR.overflow (opcode 72): if overflow, branch PC-relative
                -- branch_type="010" (same as BRR.N format)
                -- loadimm_sel='1' distinguishes from BRR.N in branch evaluator
                when "1001000" =>
                    branch_type <= "010";
                    pc_src      <= '1';
                    loadimm_sel <= '1';

                -- =============================================================
                -- FORMAT L: Load / Store / Immediate / Move
                -- =============================================================

                -- LOAD (opcode 16): R[r.dest] <- M[R[r.src]]
                -- Address R[r.src] routed via fwd_data_a (default read addr = id_rb)
                -- ex_result mux passes address using mem_to_reg flag
                when "0010000" =>
                    reg_wr_en  <= '1';
                    mem_to_reg <= '1';

                -- STORE (opcode 17): M[R[r.dest]] <- R[r.src]
                -- Address R[r.dest] needs rf_read_addr1 = id_ra
                -- Data R[r.src] needs rf_read_addr2 = id_rb
                when "0010001" =>
                    mem_wr_en  <= '1';
                    alu_src    <= '1';

                -- LOADIMM (opcode 18): R7 <- imm (upper or lower byte)
                -- loadimm_sel comes from instruction[8] in datapath
                when "0010010" =>
                    reg_wr_en  <= '1';
                    loadimm_en <= '1';

                -- MOV (opcode 19): R[r.dest] <- R[r.src]
                when "0010011" =>
                    reg_wr_en <= '1';
                    mov_en    <= '1';

                -- =============================================================
                -- Unknown opcode: safe NOP defaults
                -- =============================================================
                when others =>
                    null;

            end case;
        end if;
        -- RESET_STATE: all outputs stay at safe defaults (no writes, no branches)
    end process;

end behavioral;
