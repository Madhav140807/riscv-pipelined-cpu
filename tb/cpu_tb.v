`timescale 1ns/1ps

module cpu_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;

  cpu #(.IMEM_FILE("programs/test_basic.hex")) dut (.clk(clk), .reset(reset));

  always #5 clk = ~clk;
  
    initial begin
    $dumpfile("sim/cpu.vcd");
    $dumpvars(0, cpu_tb);
  end

  task check_reg(input [4:0] r, input [31:0] expected);
    begin
      if (dut.rf.regs[r] !== expected) begin
        $display("FAIL x%0d: got=%h expected=%h", r, dut.rf.regs[r], expected);
        errors = errors + 1;
      end else
        $display("pass x%0d = %h", r, expected);
    end
  endtask

  initial begin
    // hold reset for one cycle so the PC starts at 0
    @(posedge clk); #1;
    reset = 0;

    // run long enough for the program to finish
    repeat (40) @(posedge clk);
    #1;

    check_reg(1, 32'd0);
    check_reg(2, 32'd15);
    check_reg(3, 32'd15);
    check_reg(4, 32'h12345000);
    check_reg(5, 32'd36);
    check_reg(6, 32'd0);
    check_reg(7, 32'd1);

    if (dut.dmem.mem[0] !== 32'd15) begin
      $display("FAIL mem[0]: got=%h expected=%h", dut.dmem.mem[0], 32'd15);
      errors = errors + 1;
    end else
      $display("pass mem[0] = %h", 32'd15);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule