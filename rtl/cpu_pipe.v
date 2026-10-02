`include "defines.vh"

module cpu_pipe #(
  parameter IMEM_FILE = ""
) (
  input wire clk,
  input wire reset
);

  // Pipeline registers

  reg [31:0] if_id_pc, if_id_instr;

  reg [31:0] id_ex_pc, id_ex_rs1_val, id_ex_rs2_val, id_ex_imm;
  reg  [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
  reg  [2:0] id_ex_funct3;
  reg        id_ex_reg_write, id_ex_alu_src_b, id_ex_mem_read, id_ex_mem_write;
  reg        id_ex_branch, id_ex_jal, id_ex_jalr;
  reg  [1:0] id_ex_alu_src_a, id_ex_result_src;
  reg  [3:0] id_ex_alu_ctrl;

  reg [31:0] ex_mem_alu_result, ex_mem_rs2_val, ex_mem_pc_plus4;
  reg  [4:0] ex_mem_rd;
  reg  [2:0] ex_mem_funct3;
  reg        ex_mem_reg_write, ex_mem_mem_write;
  reg  [1:0] ex_mem_result_src;

  reg [31:0] mem_wb_alu_result, mem_wb_mem_rd, mem_wb_pc_plus4;
  reg  [4:0] mem_wb_rd;
  reg        mem_wb_reg_write;
  reg  [1:0] mem_wb_result_src;

  // IF: fetch

  reg  [31:0] pc;
  wire [31:0] if_instr;
  wire        ex_redirect;   // EX says: jump somewhere else
  wire [31:0] ex_target;

  instr_mem #(.INIT_FILE(IMEM_FILE)) imem (.addr(pc), .instr(if_instr));

  always @(posedge clk) begin
    if (reset)            pc <= 32'd0;
    else if (ex_redirect) pc <= ex_target;
    else                  pc <= pc + 32'd4;
  end

  always @(posedge clk) begin
    if (reset) begin
      if_id_pc    <= 32'd0;
      if_id_instr <= `NOP;
    end else begin
      if_id_pc    <= pc;
      if_id_instr <= if_instr;
    end
  end

  // ID: decode and read registers

  wire [4:0] id_rs1    = if_id_instr[19:15];
  wire [4:0] id_rs2    = if_id_instr[24:20];
  wire [4:0] id_rd     = if_id_instr[11:7];
  wire [2:0] id_funct3 = if_id_instr[14:12];

  wire       id_reg_write, id_alu_src_b, id_mem_read, id_mem_write;
  wire       id_branch, id_jal, id_jalr;
  wire [1:0] id_alu_src_a, id_result_src;
  wire [3:0] id_alu_ctrl;

  control ctrl (
    .opcode(if_id_instr[6:0]), .funct3(id_funct3), .funct7_5(if_id_instr[30]),
    .reg_write(id_reg_write), .alu_src_a(id_alu_src_a), .alu_src_b(id_alu_src_b),
    .mem_read(id_mem_read), .mem_write(id_mem_write), .result_src(id_result_src),
    .branch(id_branch), .jal(id_jal), .jalr(id_jalr), .alu_ctrl(id_alu_ctrl)
  );

  wire [31:0] id_imm;
  imm_gen ig (.instr(if_id_instr), .imm(id_imm));

  wire [31:0] id_rs1_val, id_rs2_val;
  reg  [31:0] wb_data;

  // write through on: WB writes and ID reads in the same cycle
  regfile #(.WRITE_THROUGH(1)) rf (
    .clk(clk), .we(mem_wb_reg_write), .rs1(id_rs1), .rs2(id_rs2),
    .rd(mem_wb_rd), .wd(wb_data), .rd1(id_rs1_val), .rd2(id_rs2_val)
  );

  always @(posedge clk) begin
    if (reset) begin
      id_ex_reg_write  <= 1'b0;
      id_ex_mem_read   <= 1'b0;
      id_ex_mem_write  <= 1'b0;
      id_ex_branch     <= 1'b0;
      id_ex_jal        <= 1'b0;
      id_ex_jalr       <= 1'b0;
      id_ex_alu_src_a  <= `A_RS1;
      id_ex_alu_src_b  <= `B_RS2;
      id_ex_result_src <= `RES_ALU;
      id_ex_alu_ctrl   <= `ALU_ADD;
      id_ex_pc         <= 32'd0;
      id_ex_rs1_val    <= 32'd0;
      id_ex_rs2_val    <= 32'd0;
      id_ex_imm        <= 32'd0;
      id_ex_rs1        <= 5'd0;
      id_ex_rs2        <= 5'd0;
      id_ex_rd         <= 5'd0;
      id_ex_funct3     <= 3'd0;
    end else begin
      id_ex_reg_write  <= id_reg_write;
      id_ex_mem_read   <= id_mem_read;
      id_ex_mem_write  <= id_mem_write;
      id_ex_branch     <= id_branch;
      id_ex_jal        <= id_jal;
      id_ex_jalr       <= id_jalr;
      id_ex_alu_src_a  <= id_alu_src_a;
      id_ex_alu_src_b  <= id_alu_src_b;
      id_ex_result_src <= id_result_src;
      id_ex_alu_ctrl   <= id_alu_ctrl;
      id_ex_pc         <= if_id_pc;
      id_ex_rs1_val    <= id_rs1_val;
      id_ex_rs2_val    <= id_rs2_val;
      id_ex_imm        <= id_imm;
      id_ex_rs1        <= id_rs1;
      id_ex_rs2        <= id_rs2;
      id_ex_rd         <= id_rd;
      id_ex_funct3     <= id_funct3;
    end
  end

  // EX: ALU, branch decision

  // forwarding will plug in here later
  wire [31:0] ex_rs1_val = id_ex_rs1_val;
  wire [31:0] ex_rs2_val = id_ex_rs2_val;

  reg [31:0] ex_alu_a;
  always @(*) begin
    case (id_ex_alu_src_a)
      `A_PC:   ex_alu_a = id_ex_pc;
      `A_ZERO: ex_alu_a = 32'd0;
      default: ex_alu_a = ex_rs1_val;
    endcase
  end

  wire [31:0] ex_alu_b = (id_ex_alu_src_b == `B_IMM) ? id_ex_imm : ex_rs2_val;
  wire [31:0] ex_alu_result;

  alu alu_u (.a(ex_alu_a), .b(ex_alu_b), .alu_ctrl(id_ex_alu_ctrl), .result(ex_alu_result));

  wire ex_taken;
  branch_unit bu (.branch(id_ex_branch), .funct3(id_ex_funct3),
                  .a(ex_rs1_val), .b(ex_rs2_val), .taken(ex_taken));

  assign ex_redirect = ex_taken | id_ex_jal | id_ex_jalr;
  assign ex_target   = id_ex_jalr ? {ex_alu_result[31:1], 1'b0}
                                  : id_ex_pc + id_ex_imm;

  always @(posedge clk) begin
    if (reset) begin
      ex_mem_reg_write  <= 1'b0;
      ex_mem_mem_write  <= 1'b0;
      ex_mem_result_src <= `RES_ALU;
      ex_mem_alu_result <= 32'd0;
      ex_mem_rs2_val    <= 32'd0;
      ex_mem_pc_plus4   <= 32'd0;
      ex_mem_rd         <= 5'd0;
      ex_mem_funct3     <= 3'd0;
    end else begin
      ex_mem_reg_write  <= id_ex_reg_write;
      ex_mem_mem_write  <= id_ex_mem_write;
      ex_mem_result_src <= id_ex_result_src;
      ex_mem_alu_result <= ex_alu_result;
      ex_mem_rs2_val    <= ex_rs2_val;
      ex_mem_pc_plus4   <= id_ex_pc + 32'd4;
      ex_mem_rd         <= id_ex_rd;
      ex_mem_funct3     <= id_ex_funct3;
    end
  end

  // MEM: data memory

  wire [31:0] mem_rd;
  data_mem dmem (.clk(clk), .mem_write(ex_mem_mem_write), .funct3(ex_mem_funct3),
                 .addr(ex_mem_alu_result), .wd(ex_mem_rs2_val), .rd(mem_rd));

  always @(posedge clk) begin
    if (reset) begin
      mem_wb_reg_write  <= 1'b0;
      mem_wb_result_src <= `RES_ALU;
      mem_wb_alu_result <= 32'd0;
      mem_wb_mem_rd     <= 32'd0;
      mem_wb_pc_plus4   <= 32'd0;
      mem_wb_rd         <= 5'd0;
    end else begin
      mem_wb_reg_write  <= ex_mem_reg_write;
      mem_wb_result_src <= ex_mem_result_src;
      mem_wb_alu_result <= ex_mem_alu_result;
      mem_wb_mem_rd     <= mem_rd;
      mem_wb_pc_plus4   <= ex_mem_pc_plus4;
      mem_wb_rd         <= ex_mem_rd;
    end
  end

  // WB: pick what gets written back

  always @(*) begin
    case (mem_wb_result_src)
      `RES_MEM: wb_data = mem_wb_mem_rd;
      `RES_PC4: wb_data = mem_wb_pc_plus4;
      default:  wb_data = mem_wb_alu_result;
    endcase
  end

endmodule