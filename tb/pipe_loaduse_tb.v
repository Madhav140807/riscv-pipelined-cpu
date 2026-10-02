`timescale 1ns/1ps

module pipe_loaduse_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;
  integer stalls = 0;

  cpu_pipe #(.IMEM_FILE("programs/test_loaduse.hex")) dut (.clk(clk), .reset(reset));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/pipe_loaduse.vcd");
    $dumpvars(0, pipe_loaduse_tb);
  end

  // count every cycle the pipeline stalls
  always @(posedge clk)
    if (!reset && dut.stall) stalls = stalls + 1;

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

    check_reg(1, 32'd7);
    check_reg(2, 32'd7);
    check_reg(3, 32'd14);
    check_reg(4, 32'd7);
    check_reg(5, 32'd7);
    check_reg(6, 32'd8);
    check_reg(7, 32'd7);
    check_reg(8, 32'd14);

    if (dut.dmem.mem[1] !== 32'd7) begin
      $display("FAIL mem[1]: got=%h expected=%h", dut.dmem.mem[1], 32'd7);
      errors = errors + 1;
    end else
      $display("pass mem[1] = %h", 32'd7);

    if (stalls !== 3) begin
      $display("FAIL stalls: got=%0d expected=3", stalls);
      errors = errors + 1;
    end else
      $display("pass stalls = 3");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule