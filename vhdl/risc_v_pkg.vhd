library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;



package risc_v_pkg is


  type t_slv_array is array (natural range <>) of std_logic_vector;
  subtype t_reg_file is t_slv_array(0 to 31)(31 downto 0);
  subtype t_imem is t_slv_array(natural range 0 to 57)(31 downto 0);
  subtype t_dmem is t_reg_file;

  -- Test program
  constant c_imem : t_imem := (
    -- (I) ADDI x1, x0, 10101
    b"00000001010100000000000010010011",
    -- (I) ADDI x2, x0, 111
    b"00000000011100000000000100010011",
    -- (I) ADDI x3, x0, 111111111100
    b"11111111110000000000000110010011",
    -- (I) ANDI x5, x1, 1011100
    b"00000101110000001111001010010011",
    -- (I) XORI x5, x5, 10101
    b"00000001010100101100001010010011",
    -- (I) ORI x6, x1, 1011100
    b"00000101110000001110001100010011",
    -- (I) XORI x6, x6, 1011100
    b"00000101110000110100001100010011",
    -- (I) ADDI x7, x1, 111
    b"00000000011100001000001110010011",
    -- (I) XORI x7, x7, 11101
    b"00000001110100111100001110010011",
    -- (I) SLLI x8, x1, 110
    b"00000000011000001001010000010011",
    -- (I) XORI x8, x8, 10101000001
    b"01010100000101000100010000010011",
    -- (I) SRLI x9, x1, 10
    b"00000000001000001101010010010011",
    -- (I) XORI x9, x9, 100
    b"00000000010001001100010010010011",
    -- (R) AND x10, x1,x2
    b"00000000001000001111010100110011",
    -- (I) XORI x10, x10, 100
    b"00000000010001010100010100010011",
    -- (R) OR x11, x1, x2
    b"00000000001000001110010110110011",
    -- (I) XORI x11, x11, 10110
    b"00000001011001011100010110010011",
    -- (R) XOR x12, x1, x2
    b"00000000001000001100011000110011",
    -- (I) XORI x12, x12, 10011
    b"00000001001101100100011000010011",
    -- (R) ADD x13, x1, x2
    b"00000000001000001000011010110011",
    -- (I) XORI x13, x13, 11101
    b"00000001110101101100011010010011",
    -- (R) SUB x14, x1, x2
    b"01000000001000001000011100110011",
    -- (I) XORI x14, x14, 1111
    b"00000000111101110100011100010011",
    -- (R) SLL x15, x2, x2
    b"00000000001000010001011110110011",
    -- (I) XORI x15, x15, 1110000001
    b"00111000000101111100011110010011",
    -- (R) SRL x16, x1, x2
    b"00000000001000001101100000110011",
    -- (I) XORI x16, x16, 1
    b"00000000000110000100100000010011",
    -- (R) SLTU x17, x2, x1
    b"00000000000100010011100010110011",
    -- (I) XORI x17, x17, 0
    b"00000000000010001100100010010011",
    -- (I) SLTIU x18, x2, 10101
    b"00000001010100010011100100010011",
    -- (I) XORI x18, x18, 0
    b"00000000000010010100100100010011",
    -- (U) LUI x19 ,0
    b"00000000000000000000100110110111",
    -- (I) XORI x19, x19, 1
    b"00000000000110011100100110010011",
    -- (I) SRAI x20, x2, 1
    b"01000000000100011101101000010011",
    -- (I) XORI x20, x20, 111111111111
    b"11111111111110100100101000010011",
    -- (R) SLT x21, x3, x1
    b"00000000000100011010101010110011",
    -- (I) XORI x21, x21, 0
    b"00000000000010101100101010010011",
    -- (I) SLTI x22, x3, 1
    b"00000000000100011010101100010011",
    -- (I) XORI x22, x22, 0
    b"00000000000010110100101100010011",
    -- (R) SRA x23, x1, x2
    b"01000000001000001101101110110011",
    -- (I) XORI x23, x23, 1
    b"00000000000110111100101110010011",
    -- (U) AUIPC x4, 100
    b"00000000000000000100001000010111",
    -- (I) SRLI x24, x4, 111
    b"00000000011100100101110000010011",
    -- (I) XORI x24, x24, 10000000
    b"00001000000011000100110000010011",
    -- (J) JAL x25, 10
    b"00000000010000000000110011101111",
    -- (U) AUIPC x4, 0
    b"00000000000000000000001000010111",
    -- (R) XOR x25, x25, x4
    b"00000000010011001100110010110011",
    -- (I) XORI x25, x25, 1
    b"00000000000111001100110010010011",
    -- (I) JALR x26, x4, 10000
    b"00000001000000100000110101100111",
    -- (R) SUB x26, x26, x4
    b"01000000010011010000110100110011",
    -- (I) ADDI x26, x26, 111111110001
    b"11111111000111010000110100010011",
    -- (S) SW x2, x1, 1
    b"00000000000100010010000010100011",
    -- (I) LW x27, x2, 1
    b"00000000000100010010110110000011",
    -- (I) XORI x27, x27, 10100
    b"00000001010011011100110110010011",
    -- (I) ADDI x28, x0, 1
    b"00000000000100000000111000010011",
    -- (I) ADDI x29, x0, 1
    b"00000000000100000000111010010011",
    -- (I) ADDI x30, x0, 1
    b"00000000000100000000111100010011",
    -- (J) JAL x0, 0
    b"00000000000000000000000001101111");

  function init_reg_file return t_reg_file;
  function init_dmem return t_dmem;

  function shift_right (data  : in std_logic_vector(31 downto 0);
                        index : in std_logic_vector) return std_logic_vector;

  function shift_left (data  : in std_logic_vector(31 downto 0);
                       index : in std_logic_vector) return std_logic_vector;

  function shift_arith_right (data  : in std_logic_vector(31 downto 0);
                              index : in std_logic_vector) return std_logic_vector;

  function to_std_logic (data : in boolean) return std_logic;

  procedure check_equal (a, b : in std_logic_vector; prefix : in string := "");


end package risc_v_pkg;


package body risc_v_pkg is


  function init_reg_file return t_reg_file is
    variable v_reg_file : t_reg_file;
  begin
    for i in t_reg_file'range loop
      v_reg_file(i) := std_logic_vector(to_unsigned(i, 32));
    end loop;
    return v_reg_file;
  end init_reg_file;

  function init_dmem return t_dmem is
    variable v_dmem : t_dmem;
  begin
    for i in t_dmem'range loop
      v_dmem(t_dmem'high-i) := std_logic_vector(to_unsigned(i, 32));
    end loop;
    return v_dmem;
  end init_dmem;

  function shift_right (data  : in std_logic_vector(31 downto 0);
                        index : in std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(shift_right(unsigned(data),
                            to_integer(unsigned(index))));
  end function shift_right;

  function shift_left (data  : in std_logic_vector(31 downto 0);
                       index : in std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(shift_left(unsigned(data),
                            to_integer(unsigned(index))));
  end function shift_left;

  function shift_arith_right (data  : in std_logic_vector(31 downto 0);
                              index : in std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(shift_right(signed(data),
                            to_integer(unsigned(index))));
  end function shift_arith_right;

  function to_std_logic (data : in boolean) return std_logic is
  begin
    if data then
      return '1';
    else
      return '0';
    end if;
  end function to_std_logic;

  procedure check_equal (a, b : in std_logic_vector; prefix : in string := "") is
  begin
    assert a = b
      report prefix & "expected 0x" & to_hstring(b) & ", got 0x" & to_hstring(a);
  end procedure check_equal;


end package body risc_v_pkg;
