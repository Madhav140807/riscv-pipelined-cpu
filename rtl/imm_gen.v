`include "defines.vh"

module imm_gen (
  input  wire [31:0] instr,
  output reg  [31:0] imm
);

  always @(*) begin
    case (instr[6:0])
      // I type: addi, loads, jalr
      `OP_IMM, `OP_LOAD, `OP_JALR:
        imm = {{20{instr[31]}}, instr[31:20]};

      // S type: stores
      `OP_STORE:
        imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

      // B type: branches
      `OP_BRANCH:
        imm = {{19{instr[31]}}, instr[31], instr[7],
               instr[30:25], instr[11:8], 1'b0};

      // U type: lui, auipc
      `OP_LUI, `OP_AUIPC:
        imm = {instr[31:12], 12'b0};

      // J type: jal
      `OP_JAL:
        imm = {{11{instr[31]}}, instr[31], instr[19:12],
               instr[20], instr[30:21], 1'b0};

      // R type and anything unknown: no immediate
      default:
        imm = 32'd0;
    endcase
  end

endmodule