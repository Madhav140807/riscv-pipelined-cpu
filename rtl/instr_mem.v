module instr_mem #(
  parameter WORDS     = 1024,
  parameter INIT_FILE = ""
) (
  input  wire [31:0] addr,
  output wire [31:0] instr
);

  localparam AW = $clog2(WORDS);   // address bits needed for WORDS slots

  reg [31:0] mem [0:WORDS-1];
  integer i;

  initial begin
    for (i = 0; i < WORDS; i = i + 1)
      mem[i] = 32'h00000013;        // fill with NOPs
    if (INIT_FILE != "")
      $readmemh(INIT_FILE, mem);    // load the program
  end


  assign instr = mem[addr[AW+1:2]];

endmodule
