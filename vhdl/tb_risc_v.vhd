library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use std.env.all;

use work.risc_v_pkg.all;


entity tb_risc_v is
end entity tb_risc_v;


architecture sim of tb_risc_v is


  signal s_clk      : std_logic := '1';
  signal s_reset_n  : std_logic := '0';
  signal s_reg_file : t_reg_file;
  signal s_dmem     : t_dmem;


begin


  s_clk     <= not s_clk after 5 ns;
  s_reset_n <= '1' after 20 ns;

  DUT : entity work.risc_v
  port map (
    reset_n_i  => s_reset_n,
    clk_i      => s_clk,
    reg_file_o => s_reg_file,
    dmem_o     => s_dmem
  );

  -- Checker
  process is
    variable v_expected : std_logic_vector(31 downto 0);
  begin
    wait until s_reset_n = '1';
    -- until program is finished
    wait for c_imem'length * 10 ns;
    -- Check register file entries
    for i in t_reg_file'range loop
      case i is
        when 0  => v_expected := 32x"0";
        when 1  => v_expected := 32x"15";
        when 2  => v_expected := 32x"7";
        when 3  => v_expected := x"FFFFFFFC";
        when 4  => v_expected := 32x"B4";
        when 31 => v_expected := 32x"1F";
        when others => v_expected := 32x"1";
      end case;
      check_equal(s_reg_file(i), v_expected, "Reg. x" & to_string(i) & ": ");
    end loop;
    -- Check data memory entries
    for i in t_dmem'range loop
      case i is
        when 2 => v_expected := 32x"15";
        when others => v_expected := std_logic_vector(to_unsigned(t_dmem'high-i, 32));
      end case;
      check_equal(s_dmem(i), v_expected, "Dmem @" & to_string(i) & ": ");
    end loop;
    stop(0);
  end process;


end architecture sim;
