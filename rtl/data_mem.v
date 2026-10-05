`include "defines.vh"

module data_mem #(
  parameter WORDS = 1024
) (
  input  wire        clk,
  input  wire        mem_write,
  input  wire [2:0]  funct3,    // access size and signedness
  input  wire [31:0] addr,
  input  wire [31:0] wd,        // data to store
  output reg  [31:0] rd         // data loaded
);

  localparam AW = $clog2(WORDS);

  reg [31:0] mem [0:WORDS-1];
  integer i;
  initial
    for (i = 0; i < WORDS; i = i + 1) mem[i] = 32'd0;

  wire [AW-1:0] idx  = addr[AW+1:2];   // which word
  wire [1:0]    off  = addr[1:0];      // which byte inside the word
  wire [31:0]   word = mem[idx];

 
  reg [31:0] new_word;
  always @(*) begin
    new_word = word;
    case (funct3[1:0])
      2'b00:   new_word[off*8 +: 8]     = wd[7:0];    // sb
      2'b01:   new_word[off[1]*16 +: 16] = wd[15:0];  // sh
      default: new_word                  = wd;        // sw
    endcase
  end

  always @(posedge clk)
    if (mem_write) mem[idx] <= new_word;


  wire [7:0]  byte_val = word[off*8 +: 8];
  wire [15:0] half_val = word[off[1]*16 +: 16];

  always @(*) begin
    case (funct3)
      `F3_LB:  rd = {{24{byte_val[7]}},  byte_val};
      `F3_LH:  rd = {{16{half_val[15]}}, half_val};
      `F3_LW:  rd = word;
      `F3_LBU: rd = {24'd0, byte_val};
      `F3_LHU: rd = {16'd0, half_val};
      default: rd = word;
    endcase
  end

endmodule