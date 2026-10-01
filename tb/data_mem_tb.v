`timescale 1ns/1ps
`include "defines.vh"

module data_mem_tb;
  reg         clk = 0;
  reg         mem_write = 0;
  reg  [2:0]  funct3 = 0;
  reg  [31:0] addr = 0, wd = 0;
  wire [31:0] rd;
  integer errors = 0;

  data_mem #(.WORDS(16)) dut (.clk(clk), .mem_write(mem_write),
    .funct3(funct3), .addr(addr), .wd(wd), .rd(rd));

  always #5 clk = ~clk;

  task store(input [2:0] f3, input [31:0] a, input [31:0] d);
    begin
      mem_write = 1; funct3 = f3; addr = a; wd = d;
      @(posedge clk); #1;
      mem_write = 0;
    end
  endtask

  task check(input [8*12-1:0] name, input [2:0] f3,
             input [31:0] a, input [31:0] expected);
    begin
      funct3 = f3; addr = a; #1;
      if (rd !== expected) begin
        $display("FAIL %0s: addr=%h got=%h expected=%h",
                 name, a, rd, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    // Word store and load
    store(`F3_SW, 32'd0, 32'h12345678);
    check("sw_lw",     `F3_LW,  32'd0, 32'h12345678);

    // Little endian: lowest byte at lowest address
    check("lbu_byte0", `F3_LBU, 32'd0, 32'h00000078);
    check("lbu_byte3", `F3_LBU, 32'd3, 32'h00000012);

    // Store one byte, rest of the word unchanged
    store(`F3_SB, 32'd1, 32'h000000AB);
    check("sb_merge",  `F3_LW,  32'd0, 32'h1234AB78);
    check("lb_signed", `F3_LB,  32'd1, 32'hFFFFFFAB);
    check("lbu_zero",  `F3_LBU, 32'd1, 32'h000000AB);

    // Halfword into the upper half of word 1
    store(`F3_SH, 32'd6, 32'h00008001);
    check("sh_merge",  `F3_LW,  32'd4, 32'h80010000);
    check("lh_signed", `F3_LH,  32'd6, 32'hFFFF8001);
    check("lhu_zero",  `F3_LHU, 32'd6, 32'h00008001);

    // No write when mem_write = 0
    funct3 = `F3_SW; addr = 32'd8; wd = 32'hDEADBEEF;
    @(posedge clk); #1;
    check("no_write",  `F3_LW,  32'd8, 32'h00000000);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule