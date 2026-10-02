`timescale 1ns/1ps

module pipe_branch_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;

  cpu_pipe #(.IMEM_FILE("programs/test_branch.hex")) dut (.clk(clk), .reset(reset));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/pipe_branch.vcd");
    $dumpvars(0, pipe_branch_tb);
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

    repeat (60) @(posedge clk);
    #1;

    check_reg(1,  32'd32);   // return address from jal
    check_reg(2,  32'd3);
    check_reg(10, 32'd0);    // flushed after taken beq
    check_reg(11, 32'd24);   // auipc
    check_reg(12, 32'd7);    // ran after return
    check_reg(13, 32'd9);    // function body
    check_reg(14, 32'd0);    // flushed after jalr

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule