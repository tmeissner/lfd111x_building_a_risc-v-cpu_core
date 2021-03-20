library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use std.env.all;

use work.risc_v_pkg.all;


entity risc_v is
  port (
    reset_n_i  : in std_logic;
    clk_i      : in std_logic;
    -- test out
    reg_file_o : out t_reg_file;
    dmem_o     : out t_dmem
  );
end entity;



architecture rtl of risc_v is


  signal s_reg_file : t_reg_file;
  signal s_dmem     : t_dmem;

  signal s_instr      : std_logic_vector(31 downto 0);
  signal s_imm        : std_logic_vector(31 downto 0);
  signal s_dec_bits   : std_logic_vector(10 downto 0);
  signal s_src1_value : std_logic_vector(31 downto 0);
  signal s_src2_value : std_logic_vector(31 downto 0);
  signal s_ld_data    : std_logic_vector(31 downto 0);
  signal s_result     : std_logic_vector(31 downto 0);
  signal s_sltu_rslt  : std_logic_vector(31 downto 0);
  signal s_sltiu_rslt : std_logic_vector(31 downto 0);

  signal s_pc          : unsigned(31 downto 0);
  signal s_next_pc     : unsigned(31 downto 0);
  signal s_br_tgt_br   : unsigned(31 downto 0);
  signal s_jalr_tgt_pc : unsigned(31 downto 0);

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
  signal s_is_lui       : boolean;
  signal s_is_auipc     : boolean;
  signal s_is_jal       : boolean;
  signal s_is_jalr      : boolean;
  signal s_is_beq       : boolean;
  signal s_is_bne       : boolean;
  signal s_is_blt       : boolean;
  signal s_is_bge       : boolean;
  signal s_is_bltu      : boolean;
  signal s_is_bgeu      : boolean;
  signal s_is_addi      : boolean;
  signal s_is_slti      : boolean;
  signal s_is_sltiu     : boolean;
  signal s_is_xori      : boolean;
  signal s_is_ori       : boolean;
  signal s_is_andi      : boolean;
  signal s_is_slli      : boolean;
  signal s_is_srli      : boolean;
  signal s_is_srai      : boolean;
  signal s_is_add       : boolean;
  signal s_is_sub       : boolean;
  signal s_is_sll       : boolean;
  signal s_is_slt       : boolean;
  signal s_is_sltu      : boolean;
  signal s_is_xor       : boolean;
  signal s_is_srl       : boolean;
  signal s_is_sra       : boolean;
  signal s_is_or        : boolean;
  signal s_is_and       : boolean;
  signal s_is_load      : boolean;
  signal s_is_store     : boolean;
  signal s_src_sgn_eq   : boolean;
  signal s_imm_sgn_eq   : boolean;

  alias a_opcode : std_logic_vector(6 downto 0) is s_instr(6 downto 0);
  alias a_rd     : std_logic_vector(4 downto 0) is s_instr(11 downto 7);
  alias a_funct3 : std_logic_vector(2 downto 0) is s_instr(14 downto 12);
  alias a_rs1    : std_logic_vector(4 downto 0) is s_instr(19 downto 15);
  alias a_rs2    : std_logic_vector(4 downto 0) is s_instr(24 downto 20);
  alias a_funct7 : std_logic_vector(6 downto 0) is s_instr(31 downto 25);

begin


  -- Test outs
  reg_file_o <= s_reg_file;
  dmem_o     <= s_dmem;

  -- prog counter next state logic
  s_next_pc <= 32x"0"        when not reset_n_i          else
               s_br_tgt_br   when s_taken_br or s_is_jal else
               s_jalr_tgt_pc when s_is_jalr              else
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
  s_is_lui   <= std_match(s_dec_bits, b"-_---_0110111");
  s_is_auipc <= std_match(s_dec_bits, b"-_---_0010111");
  s_is_jal   <= std_match(s_dec_bits, b"-_---_1101111");
  s_is_jalr  <= std_match(s_dec_bits, b"-_000_1100111");
  s_is_beq   <= std_match(s_dec_bits, b"-_000_1100011");
  s_is_bne   <= std_match(s_dec_bits, b"-_001_1100011");
  s_is_blt   <= std_match(s_dec_bits, b"-_100_1100011");
  s_is_bge   <= std_match(s_dec_bits, b"-_101_1100011");
  s_is_bltu  <= std_match(s_dec_bits, b"-_110_1100011");
  s_is_bgeu  <= std_match(s_dec_bits, b"-_111_1100011");
  s_is_addi  <= std_match(s_dec_bits, b"-_000_0010011");
  s_is_slti  <= std_match(s_dec_bits, b"-_010_0010011");
  s_is_sltiu <= std_match(s_dec_bits, b"-_011_0010011");
  s_is_xori  <= std_match(s_dec_bits, b"-_100_0010011");
  s_is_ori   <= std_match(s_dec_bits, b"-_110_0010011");
  s_is_andi  <= std_match(s_dec_bits, b"-_111_0010011");
  s_is_slli  <= s_dec_bits = b"0_001_0010011";
  s_is_srli  <= s_dec_bits = b"0_101_0010011";
  s_is_srai  <= s_dec_bits = b"1_101_0010011";
  s_is_add   <= s_dec_bits = b"0_000_0110011";
  s_is_sub   <= s_dec_bits = b"1_000_0110011";
  s_is_sll   <= s_dec_bits = b"0_001_0110011";
  s_is_slt   <= s_dec_bits = b"0_010_0110011";
  s_is_sltu  <= s_dec_bits = b"0_011_0110011";
  s_is_xor   <= s_dec_bits = b"0_100_0110011";
  s_is_srl   <= s_dec_bits = b"0_101_0110011";
  s_is_sra   <= s_dec_bits = b"1_101_0110011";
  s_is_or    <= s_dec_bits = b"0_110_0110011";
  s_is_and   <= s_dec_bits = b"0_111_0110011";
  -- LB, LH, LW, LBU, LHU
  s_is_load <= a_opcode = "0000011";
  -- SB, SH, SW
  s_is_store <= s_is_s_instr;

  -- Some subexpressions
  s_src_sgn_eq <= s_src1_value(31) = s_src2_value(31);
  s_imm_sgn_eq <= s_src1_value(31) = s_imm(31);
  -- SLTU & SLTI (set if less than, unsigned)
  s_sltu_rslt  <= 31x"0" & to_std_logic(unsigned(s_src1_value) < unsigned(s_src2_value));
  s_sltiu_rslt <= 31x"0" & to_std_logic(unsigned(s_src1_value) < unsigned(s_imm));
  -- ALU
  s_result <=
    s_src1_value and s_imm                                        when s_is_andi    else
    s_src1_value or  s_imm                                        when s_is_ori     else
    s_src1_value xor s_imm                                        when s_is_xori    else
    std_logic_vector(signed(s_src1_value) + signed(s_imm))        when s_is_addi or
                                                                       s_is_load or
                                                                       s_is_store   else
    shift_left(s_src1_value, s_imm(5 downto 0))                   when s_is_slli    else
    shift_right(s_src1_value, s_imm(5 downto 0))                  when s_is_srli    else
    s_src1_value and s_src2_value                                 when s_is_and     else
    s_src1_value or  s_src2_value                                 when s_is_or      else
    s_src1_value xor s_src2_value                                 when s_is_xor     else
    std_logic_vector(signed(s_src1_value) + signed(s_src2_value)) when s_is_add     else
    std_logic_vector(signed(s_src1_value) - signed(s_src2_value)) when s_is_sub     else
    shift_left(s_src1_value, s_src2_value(4 downto 0))            when s_is_sll     else
    shift_right(s_src1_value, s_src2_value(4 downto 0))           when s_is_srl     else
    s_sltu_rslt                                                   when s_is_sltu    else
    s_sltiu_rslt                                                  when s_is_sltiu   else
    s_imm(31 downto 12) & 12x"0"                                  when s_is_lui     else
    std_logic_vector(s_pc + unsigned(s_imm))                      when s_is_auipc   else
    std_logic_vector(s_pc + 4)                                    when s_is_jal or
                                                                       s_is_jalr    else
    s_sltu_rslt                                                   when s_is_slt and
                                                                       s_src_sgn_eq else
    31x"0" & s_src1_value(31)                                     when s_is_slt     else
    s_sltiu_rslt                                                  when s_is_slti and
                                                                       s_imm_sgn_eq else
    31x"0" & s_src1_value(31)                                     when s_is_slti    else
    shift_arith_right(s_src1_value, s_src2_value(4 downto 0))     when s_is_sra     else
    shift_arith_right(s_src1_value, s_imm(4 downto 0))            when s_is_srai    else
    32x"0";

  -- Branch logic
  s_taken_br <= s_src1_value  = s_src2_value                     when s_is_beq  else
                s_src1_value /= s_src2_value                     when s_is_bne  else
                signed(s_src1_value)   <  signed(s_src2_value)   when s_is_blt  else
                signed(s_src1_value)   >= signed(s_src2_value)   when s_is_bge  else
                unsigned(s_src1_value) <  unsigned(s_src2_value) when s_is_bltu else
                unsigned(s_src1_value) >= unsigned(s_src2_value) when s_is_bgeu else
                false;
  s_br_tgt_br   <= s_pc + unsigned(s_imm);
  s_jalr_tgt_pc <= unsigned(s_src1_value) + unsigned(s_imm);

  -- Register file
  process (clk_i) is
    variable v_value : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk_i) then
      if reset_n_i = '0' then
        s_reg_file <= init_reg_file;
      elsif s_rd_valid and a_rd /= 5x"0" then
        v_value := std_logic_vector(s_ld_data) when s_is_load else s_result;
        s_reg_file(to_integer(unsigned(a_rd))) <= v_value;
      end if;
    end if;
  end process;

  s_src1_value <= s_reg_file(to_integer(unsigned(a_rs1))) when s_rs1_valid else
                  (others => '0');
  s_src2_value <= s_reg_file(to_integer(unsigned(a_rs2))) when s_rs2_valid else
                  (others => '0');

  -- Data memory
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if reset_n_i = '0' then
        s_dmem <= init_dmem;
      elsif s_is_store then
        s_dmem(to_integer(unsigned(s_result(6 downto 2)))) <= std_logic_vector(s_src2_value);
      end if;
    end if;
  end process;

  s_ld_data <= s_dmem(to_integer(unsigned(s_result(6 downto 2)))) when s_is_load else
               (others => '0');


end architecture rtl;
