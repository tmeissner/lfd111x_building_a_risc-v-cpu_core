library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity risc_v is
  port (
    reset_n_i : in std_logic;
    clk_i     : in std_logic
  );
end entity;



architecture rtl of risc_v is

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

  signal s_reg_file : t_reg_file;

  signal s_instr    : std_logic_vector(31 downto 0);
  signal s_imm      : std_logic_vector(31 downto 0);
  signal s_dec_bits : std_logic_vector(10 downto 0);
  signal s_src1_value : std_logic_vector(31 downto 0);
  signal s_src2_value : std_logic_vector(31 downto 0);

  signal s_pc        : unsigned(31 downto 0);
  signal s_next_pc   : unsigned(31 downto 0);
  signal s_br_tgt_br : unsigned(31 downto 0);

  signal s_result : signed(31 downto 0);

  signal s_taken_br     : boolean;
  signal s_is_r_instr   : boolean;
  signal s_is_i_instr   : boolean;
  signal s_is_s_instr   : boolean;
  signal s_is_b_instr   : boolean;
  signal s_is_u_instr   : boolean;
  signal s_is_j_instr   : boolean;
  signal s_rd_valid     : boolean;
  signal s_funct3_valid : boolean;
  signal s_rs1_valid    : boolean;
  signal s_rs2_valid    : boolean;
  signal s_funct7_valid : boolean;
  signal s_imm_valid    : boolean;
  signal s_is_beq       : boolean;
  signal s_is_bne       : boolean;
  signal s_is_blt       : boolean;
  signal s_is_bge       : boolean;
  signal s_is_bltu      : boolean;
  signal s_is_bgeu      : boolean;
  signal s_is_addi      : boolean;
  signal s_is_add       : boolean;

  alias a_opcode : std_logic_vector(6 downto 0) is s_instr(6 downto 0);
  alias a_rd     : std_logic_vector(4 downto 0) is s_instr(11 downto 7);
  alias a_funct3 : std_logic_vector(2 downto 0) is s_instr(14 downto 12);
  alias a_rs1    : std_logic_vector(4 downto 0) is s_instr(19 downto 15);
  alias a_rs2    : std_logic_vector(4 downto 0) is s_instr(24 downto 20);
  alias a_funct7 : std_logic_vector(6 downto 0) is s_instr(31 downto 25);

begin

  -- prog counter next state logic
  s_next_pc <= 32x"0"      when not reset_n_i  else
               s_br_tgt_br when s_taken_br else
               s_pc + 4;

  -- prog counter register
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      s_pc <= s_next_pc;
    end if;
  end process;

  -- Instruction memory
  s_instr <= c_imem(to_integer(s_pc(31 downto 2)));

  -- Decode
  -- Decode instruction type
  s_is_r_instr <= s_instr(6 downto 2) = "01011" or
                  s_instr(6 downto 2) = "01100" or
                  s_instr(6 downto 2) = "01110" or
                  s_instr(6 downto 2) = "10100";
  s_is_i_instr <= std_match(s_instr(6 downto 2), "0000-") or
                  std_match(s_instr(6 downto 2), "001-0") or
                  s_instr(6 downto 2) = "11001";
  s_is_s_instr <= std_match(s_instr(6 downto 2), "0100-");
  s_is_b_instr <= s_instr(6 downto 2) =  "11000";
  s_is_u_instr <= std_match(s_instr(6 downto 2), "0-101");
  s_is_j_instr <= s_instr(6 downto 2) =  "11011";

  -- Extract instruction fields
   s_imm <= (31 downto 11 => s_instr(31),
             10 downto 0  => s_instr(30 downto 20)) when s_is_i_instr else
            (31 downto 11 => s_instr(31),
             10 downto  5 => s_instr(30 downto 25),
              4 downto  0 => s_instr(11 downto 7))  when s_is_s_instr else
            (31 downto 12 => s_instr(31),
                       11 => s_instr(7),
             10 downto  5 => s_instr(30 downto 25),
              4 downto  1 => s_instr(11 downto 8),
                        0 => '0')                   when s_is_b_instr else
            (          31 => s_instr(31),
             30 downto 12 => s_instr(30 downto 12),
             11 downto  0 => 12x"0")                when s_is_u_instr else
            (31 downto 20 => s_instr(31),
             19 downto 12 => s_instr(19 downto 12),
                       11 => s_instr(20),
             10 downto  1 => s_instr(30 downto 21),
                        0 => '0')                   when s_is_j_instr else
            32x"0";

  -- Calculate instruction fields valids
  s_rd_valid     <= s_is_r_instr or s_is_i_instr or s_is_u_instr or s_is_j_instr;
  s_funct3_valid <= s_is_r_instr or s_is_i_instr or s_is_s_instr or s_is_b_instr;
  s_rs1_valid    <= s_funct3_valid;
  s_rs2_valid    <= s_is_r_instr or s_is_s_instr or s_is_b_instr;
  s_funct7_valid <= s_is_r_instr;
  s_imm_valid    <= not s_is_r_instr;

  -- Instruction code decoding
  s_dec_bits <= (a_funct7(5), a_funct3, a_opcode);
  s_is_beq   <= std_match(s_dec_bits, b"-_000_1100011");
  s_is_bne   <= std_match(s_dec_bits, b"-_001_1100011");
  s_is_blt   <= std_match(s_dec_bits, b"-_100_1100011");
  s_is_bge   <= std_match(s_dec_bits, b"-_101_1100011");
  s_is_bltu  <= std_match(s_dec_bits, b"-_110_1100011");
  s_is_bgeu  <= std_match(s_dec_bits, b"-_111_1100011");
  s_is_addi  <= std_match(s_dec_bits, b"-_000_0010011");
  s_is_add   <= s_dec_bits =  b"0_000_0110011";

  -- ALU
  s_result <= signed(s_src1_value) + signed(s_imm)        when s_is_addi else
              signed(s_src1_value) + signed(s_src2_value) when s_is_add  else
              32x"0";

  -- Branch logic
  s_taken_br <= s_src1_value  = s_src2_value                     when s_is_beq  else
                s_src1_value /= s_src2_value                     when s_is_bne  else
                signed(s_src1_value)   <  signed(s_src2_value)   when s_is_blt  else
                signed(s_src1_value)   >= signed(s_src2_value)   when s_is_bge  else
                unsigned(s_src1_value) <  unsigned(s_src2_value) when s_is_bltu else
                unsigned(s_src1_value) >= unsigned(s_src2_value) when s_is_bgeu else
                false;
  s_br_tgt_br <= s_pc + unsigned(s_imm);

  -- Register file
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if reset_n_i = '0' then
        s_reg_file <= (others => 32x"0");
      else
        if s_rd_valid and a_rd /= 5x"0" then
          s_reg_file(to_integer(unsigned(a_rd))) <= std_logic_vector(s_result);
        end if;
      end if;
    end if;
  end process;

  s_src1_value <= s_reg_file(to_integer(unsigned(a_rs1))) when s_rs1_valid else
                  (others => '0');
  s_src2_value <= s_reg_file(to_integer(unsigned(a_rs2))) when s_rs2_valid else
                  (others => '0');

end architecture rtl;
