`include "defines.vh"

module cpu #(
  parameter IMEM_FILE = ""
) (
  input wire clk,
  input wire reset
);

  // ================= FETCH =================
  reg  [31:0] pc;
  wire [31:0] pc_plus4 = pc + 32'd4;
  wire [31:0] instr;

  instr_mem #(.INIT_FILE(IMEM_FILE)) imem (.addr(pc), .instr(instr));

  // ================= DECODE =================
  wire [6:0] opcode   = instr[6:0];
  wire [4:0] rd       = instr[11:7];
  wire [2:0] funct3   = instr[14:12];
  wire [4:0] rs1      = instr[19:15];
  wire [4:0] rs2      = instr[24:20];
  wire       funct7_5 = instr[30];

  wire       reg_write, alu_src_b, mem_read, mem_write;
  wire       branch, jal, jalr;
  wire [1:0] alu_src_a, result_src;
  wire [3:0] alu_ctrl;

  control ctrl (
    .opcode(opcode), .funct3(funct3), .funct7_5(funct7_5),
    .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
    .mem_read(mem_read), .mem_write(mem_write), .result_src(result_src),
    .branch(branch), .jal(jal), .jalr(jalr), .alu_ctrl(alu_ctrl)
  );

  wire [31:0] imm;
  imm_gen ig (.instr(instr), .imm(imm));

  wire [31:0] rs1_val, rs2_val;
  reg  [31:0] wb_data;

  regfile #(.WRITE_THROUGH(0)) rf (
    .clk(clk), .we(reg_write), .rs1(rs1), .rs2(rs2),
    .rd(rd), .wd(wb_data), .rd1(rs1_val), .rd2(rs2_val)
  );

  // ================= EXECUTE =================
  reg [31:0] alu_a;
  always @(*) begin
    case (alu_src_a)
      `A_PC:   alu_a = pc;
      `A_ZERO: alu_a = 32'd0;
      default: alu_a = rs1_val;
    endcase
  end

  wire [31:0] alu_b = (alu_src_b == `B_IMM) ? imm : rs2_val;
  wire [31:0] alu_result;

  alu alu_u (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result));

  wire taken;
  branch_unit bu (.branch(branch), .funct3(funct3),
                  .a(rs1_val), .b(rs2_val), .taken(taken));

  // ================= MEMORY =================
  wire [31:0] mem_rd;
  data_mem dmem (.clk(clk), .mem_write(mem_write), .funct3(funct3),
                 .addr(alu_result), .wd(rs2_val), .rd(mem_rd));

  // ================= WRITEBACK =================
  always @(*) begin
    case (result_src)
      `RES_MEM: wb_data = mem_rd;
      `RES_PC4: wb_data = pc_plus4;
      default:  wb_data = alu_result;
    endcase
  end

  // ================= NEXT PC =================
  wire [31:0] pc_target = pc + imm;   // branches and jal
  wire [31:0] pc_next   = jalr          ? {alu_result[31:1], 1'b0} :
                          (jal | taken) ? pc_target :
                                          pc_plus4;

  always @(posedge clk) begin
    if (reset) pc <= 32'd0;
    else       pc <= pc_next;
  end

endmodule