library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use std.env.all;


entity tb_risc_v is
end entity tb_risc_v;


architecture sim of tb_risc_v is


  signal s_clk     : std_logic := '1';
  signal s_reset_n : std_logic := '0';


begin


  s_clk     <= not s_clk after 5 ns;
  s_reset_n <= '1' after 20 ns;


  DUT : entity work.risc_v
  port map (
    reset_n_i => s_reset_n,
    clk_i     => s_clk
  );


  process is
  begin
    wait for 380 ns;
    stop(0);
  end process;


end architecture sim;
