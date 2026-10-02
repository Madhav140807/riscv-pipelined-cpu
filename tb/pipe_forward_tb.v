`timescale 1ns/1ps

module pipe_forward_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;

  cpu_pipe #(.IMEM_FILE("programs/test_forward.hex")) dut (.clk(clk), .reset(reset));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/pipe_forward.vcd");
    $dumpvars(0, pipe_forward_tb);
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
    @(posedge clk); #1;
    reset = 0;

    repeat (40) @(posedge clk);
    #1;

    check_reg(1, 32'd5);
    check_reg(2, 32'd8);
    check_reg(3, 32'd13);
    check_reg(4, 32'd8);
    check_reg(5, 32'h00001004);
    check_reg(6, 32'h00002008);
    check_reg(7, 32'd2);
    check_reg(8, 32'd2);
    check_reg(9, 32'd8);

    if (dut.dmem.mem[0] !== 32'd8) begin
      $display("FAIL mem[0]: got=%h expected=%h", dut.dmem.mem[0], 32'd8);
      errors = errors + 1;
    end else
      $display("pass mem[0] = %h", 32'd8);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule