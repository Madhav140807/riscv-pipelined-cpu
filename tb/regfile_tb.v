`timescale 1ns/1ps

module regfile_tb;
  reg        clk = 0;
  reg        we  = 0;
  reg  [4:0] rs1 = 0, rs2 = 0, rd = 0;
  reg [31:0] wd  = 0;
  wire [31:0] rd1, rd2;
  integer errors = 0;

  regfile dut (.clk(clk), .we(we), .rs1(rs1), .rs2(rs2),
               .rd(rd), .wd(wd), .rd1(rd1), .rd2(rd2));

  always #5 clk = ~clk;  // 10 ns clock period

  task write_reg(input [4:0] r, input [31:0] d);
    begin
      we = 1; rd = r; wd = d;
      @(posedge clk); #1;
      we = 0;
    end
  endtask

  task check(input [31:0] got, input [31:0] expected,
             input [8*12-1:0] name);
    begin
      if (got !== expected) begin
        $display("FAIL %0s: got=%h expected=%h", name, got, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    // 1. Basic write then read
    write_reg(5'd5, 32'hDEADBEEF);
    rs1 = 5'd5; #1;
    check(rd1, 32'hDEADBEEF, "write_read");

    // 2. Writes to x0 are ignored
    write_reg(5'd0, 32'd123);
    rs1 = 5'd0; #1;
    check(rd1, 32'd0, "x0_zero");

    // 3. Two reads at once
    write_reg(5'd6, 32'd42);
    rs1 = 5'd5; rs2 = 5'd6; #1;
    check(rd1, 32'hDEADBEEF, "dual_rd1");
    check(rd2, 32'd42,       "dual_rd2");


    we = 0; rd = 5'd5; wd = 32'd0;
    @(posedge clk); #1;
    rs1 = 5'd5; #1;
    check(rd1, 32'hDEADBEEF, "we_off");

    
    we = 1; rd = 5'd7; wd = 32'h1234; rs1 = 5'd7; #1;
    check(rd1, 32'h1234, "bypass");
    @(posedge clk); #1; we = 0;
    check(rd1, 32'h1234, "bypass_saved");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule