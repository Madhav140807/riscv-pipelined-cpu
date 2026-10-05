module regfile #(
  parameter WRITE_THROUGH = 1    
) (
  input  wire        clk,
  input  wire        we,
  input  wire [4:0]  rs1,
  input  wire [4:0]  rs2,
  input  wire [4:0]  rd,
  input  wire [31:0] wd,
  output wire [31:0] rd1,
  output wire [31:0] rd2
);

  reg [31:0] regs [0:31];
  integer i;
  initial
    for (i = 0; i < 32; i = i + 1) regs[i] = 32'd0;  // simulation only

  always @(posedge clk) begin
    if (we && rd != 5'd0)
      regs[rd] <= wd;
  end

  assign rd1 = (rs1 == 5'd0)                       ? 32'd0 :
               (WRITE_THROUGH && we && rd == rs1)  ? wd    :
                                                     regs[rs1];

  assign rd2 = (rs2 == 5'd0)                       ? 32'd0 :
               (WRITE_THROUGH && we && rd == rs2)  ? wd    :
                                                     regs[rs2];

endmodule