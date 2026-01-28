library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterFile is
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
end RegisterFile;

architecture behavioral of RegisterFile is

    type reg_array_t is array (0 to 7) of std_logic_vector(15 downto 0);
    signal regs : reg_array_t := (others => x"0000");

begin

    -- Synchronous write on falling edge
    process(clk)
    begin
        if falling_edge(clk) then
            if wr_en = '1' then
                regs(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    -- Asynchronous reads with write-through forwarding
    -- If reading the same address being written this cycle, forward write_data
    read_data1 <= write_data when (wr_en = '1' and read_addr1 = write_addr)
                  else regs(to_integer(unsigned(read_addr1)));

    read_data2 <= write_data when (wr_en = '1' and read_addr2 = write_addr)
                  else regs(to_integer(unsigned(read_addr2)));

end behavioral;
