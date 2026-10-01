`include "defines.vh"

module branch_unit (
  input  wire        branch,   // from control: is this a branch?
  input  wire [2:0]  funct3,   // which kind of branch
  input  wire [31:0] a,        // rs1 value
  input  wire [31:0] b,        // rs2 value
  output reg         taken
);

  reg cond;

  always @(*) begin
    case (funct3)
      `F3_BEQ:  cond = (a == b);
      `F3_BNE:  cond = (a != b);
      `F3_BLT:  cond = ($signed(a) <  $signed(b));
      `F3_BGE:  cond = ($signed(a) >= $signed(b));
      `F3_BLTU: cond = (a <  b);
      `F3_BGEU: cond = (a >= b);
      default:  cond = 1'b0;   // invalid branch type: never take
    endcase
    taken = branch & cond;
  end

endmodule