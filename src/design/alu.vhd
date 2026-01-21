library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    port(
        alu_mode   : in  std_logic_vector(2 downto 0);
        op1        : in  std_logic_vector(15 downto 0);
        op2        : in  std_logic_vector(15 downto 0);
        alu_result : out std_logic_vector(15 downto 0);
        flag_z     : out std_logic;
        flag_n     : out std_logic;
        flag_v     : out std_logic  -- overflow: MUL result exceeds 16-bit signed range
    );
end ALU;

architecture behavioral of ALU is
    signal result_buf : std_logic_vector(15 downto 0);
    signal overflow   : std_logic;
begin

    process(alu_mode, op1, op2)
        variable temp    : signed(16 downto 0);   -- 17 bits for ADD/SUB overflow
        variable mul_full : signed(31 downto 0);  -- 32 bits for full 16x16 multiply
    begin
        overflow <= '0';

        case alu_mode is
            -- NOP (opcode 0)
            when "000" =>
                result_buf <= (others => '0');

            -- ADD (opcode 1): R[ra] <- R[rb] + R[rc]
            when "001" =>
                temp := resize(signed(op1), 17) + resize(signed(op2), 17);
                result_buf <= std_logic_vector(temp(15 downto 0));

            -- SUB (opcode 2): R[ra] <- R[rb] - R[rc]
            when "010" =>
                temp := resize(signed(op1), 17) - resize(signed(op2), 17);
                result_buf <= std_logic_vector(temp(15 downto 0));

            -- MUL (opcode 3): R[ra] <- R[rb] x R[rc]
            -- Full 16-bit signed multiply. Overflow if result outside [-32768, 32767].
            when "011" =>
                mul_full := signed(op1) * signed(op2);
                result_buf <= std_logic_vector(mul_full(15 downto 0));
                -- Overflow: check if upper 17 bits are not all-zero or all-one
                -- (i.e., the 32-bit result doesn't fit in 16-bit signed)
                if mul_full(31 downto 15) /= "00000000000000000" and
                   mul_full(31 downto 15) /= "11111111111111111" then
                    overflow <= '1';
                end if;

            -- NAND (opcode 4): R[ra] <- R[rb] NAND R[rc]
            when "100" =>
                result_buf <= op1 nand op2;

            -- SHL (opcode 5): R[ra] shifted left by c1 bits
            when "101" =>
                result_buf <= std_logic_vector(
                    shift_left(unsigned(op1), to_integer(unsigned(op2(3 downto 0))))
                );

            -- SHR (opcode 6): R[ra] shifted right by c1 bits (logical)
            when "110" =>
                result_buf <= std_logic_vector(
                    shift_right(unsigned(op1), to_integer(unsigned(op2(3 downto 0))))
                );

            -- TEST (opcode 7): flags only, result = op1
            when "111" =>
                result_buf <= op1;

            when others =>
                result_buf <= (others => '0');
        end case;
    end process;

    alu_result <= result_buf;

    flag_z <= '1' when result_buf = x"0000" else '0';
    flag_n <= result_buf(15);
    flag_v <= overflow;

end behavioral;
