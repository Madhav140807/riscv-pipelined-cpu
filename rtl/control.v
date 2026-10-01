`include "defines.vh"

module control (
  input  wire [6:0] opcode,
  input  wire [2:0] funct3,
  input  wire       funct7_5,     // instr[30]
  output reg        reg_write,
  output reg  [1:0] alu_src_a,
  output reg        alu_src_b,
  output reg        mem_read,
  output reg        mem_write,
  output reg  [1:0] result_src,
  output reg        branch,
  output reg        jal,
  output reg        jalr,
  output reg  [3:0] alu_ctrl
);

  always @(*) begin
    // Defaults: do nothing
    reg_write  = 1'b0;
    alu_src_a  = `A_RS1;
    alu_src_b  = `B_RS2;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    result_src = `RES_ALU;
    branch     = 1'b0;
    jal        = 1'b0;
    jalr       = 1'b0;
    alu_ctrl   = `ALU_ADD;

    case (opcode)
      `OP_REG: begin
        reg_write = 1'b1;
        alu_ctrl  = {funct7_5, funct3};
      end

      `OP_IMM: begin
        reg_write = 1'b1;
        alu_src_b = `B_IMM;
        // Only shift right uses bit 30 (srli vs srai)
        alu_ctrl  = (funct3 == 3'b101) ? {funct7_5, funct3}
                                       : {1'b0, funct3};
      end

      `OP_LOAD: begin
        reg_write  = 1'b1;
        alu_src_b  = `B_IMM;
        mem_read   = 1'b1;
        result_src = `RES_MEM;
      end

      `OP_STORE: begin
        alu_src_b = `B_IMM;
        mem_write = 1'b1;
      end

      `OP_BRANCH: begin
        branch = 1'b1;
      end

      `OP_JAL: begin
        reg_write  = 1'b1;
        jal        = 1'b1;
        result_src = `RES_PC4;
      end

      `OP_JALR: begin
        reg_write  = 1'b1;
        jalr       = 1'b1;
        alu_src_b  = `B_IMM;
        result_src = `RES_PC4;
      end

      `OP_LUI: begin
        reg_write = 1'b1;
        alu_src_a = `A_ZERO;
        alu_src_b = `B_IMM;
      end

      `OP_AUIPC: begin
        reg_write = 1'b1;
        alu_src_a = `A_PC;
        alu_src_b = `B_IMM;
      end

      default: ; // unknown instruction: keep safe defaults
    endcase
  end

endmodule