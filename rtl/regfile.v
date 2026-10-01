module regfile (
  input  wire        clk,
  input  wire        we,     // write enable: 1 = write this cycle
  input  wire [4:0]  rs1,    // first register to read
  input  wire [4:0]  rs2,    // second register to read
  input  wire [4:0]  rd,     // register to write
  input  wire [31:0] wd,     // data to write
  output wire [31:0] rd1,    // value of rs1
  output wire [31:0] rd2     // value of rs2
);

  reg [31:0] regs [0:31];

  // Write on the clock edge, never to x0
  always @(posedge clk) begin
    if (we && rd != 5'd0)
      regs[rd] <= wd;
  end

  // Read instantly. x0 is always 0.
  // If reading the register being written right now, return the new value.
  assign rd1 = (rs1 == 5'd0)           ? 32'd0 :
               (we && rd == rs1)        ? wd    :
                                          regs[rs1];

  assign rd2 = (rs2 == 5'd0)           ? 32'd0 :
               (we && rd == rs2)        ? wd    :
                                          regs[rs2];

endmodule