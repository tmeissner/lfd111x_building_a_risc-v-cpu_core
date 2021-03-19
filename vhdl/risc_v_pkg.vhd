library ieee;
  use ieee.std_logic_1164.all;


package risc_v_pkg is


  type t_slv_array is array (natural range <>) of std_logic_vector;
  subtype t_reg_file is t_slv_array(0 to 31)(31 downto 0);
  subtype t_imem is t_slv_array(natural range 0 to 8)(31 downto 0);


  -- Test program
  constant c_imem : t_imem := (
    -- ADDI, x14, x0, 0
    b"0000_0000_0000_0000_0000_0111_0001_0011",
    -- ADDI, x12, x0, 1010
    b"0000_0000_1010_0000_0000_0110_0001_0011",
    -- ADDI, x13, x0, 1
    b"0000_0000_0001_0000_0000_0110_1001_0011",
    -- LOOP begin
    -- ADD, x14, x13, x14
    b"0000_0000_1110_0110_1000_0111_0011_0011",
    -- ADDI, x13, x13, 1
    b"0000_0000_0001_0110_1000_0110_1001_0011",
    -- BLT, x13, x12, 1111111111000 (branch to LOOP begin if x13 < x12)
    b"1111_1110_1100_0110_1100_1100_1110_0011",
    -- ADDI, x0, x0, 1010 (Test write ignore to x0)
    b"0000_0000_1010_0000_0000_0000_0001_0011",
    -- ADDI, x30, x14, 111111010100
    b"1111_1101_0100_0111_0000_1111_0001_0011",
    -- BGE, x0, x0, 0 (Infinite loop)
    b"0000_0000_0000_0000_0101_0000_0110_0011");


end package risc_v_pkg;
