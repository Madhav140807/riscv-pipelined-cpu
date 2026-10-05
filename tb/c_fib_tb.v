`timescale 1ns/1ps

module c_fib_tb;
  reg clk = 0;
  reg reset = 1;

  wire        halted;
  wire [31:0] cycles, instret, stalls, flushes;

  cpu_pipe #(.IMEM_FILE("build/fib.hex")) dut (
    .clk(clk), .reset(reset), .halted(halted),
    .cycle_count(cycles), .instret_count(instret),
    .stall_count(stalls), .flush_count(flushes)
  );

  always #5 clk = ~clk;

  // same image in data memory, so constants and globals are where the code expects
  initial begin
    #1 $readmemh("build/fib.hex", dut.dmem.mem);
  end

  initial begin
    #500000;
    $display("FAIL timeout: CPU never halted");
    $finish;
  end

  initial begin
    @(posedge clk); #1;
    reset = 0;

    wait (halted);
    repeat (5) @(posedge clk);
    #1;

    $display("cycles=%0d instret=%0d stalls=%0d flushes=%0d CPI=%0.3f",
             cycles, instret, stalls, flushes, cycles * 1.0 / instret);

    // main's return value is in a0 (x10)
    if (dut.rf.regs[10] === 32'd55) begin
      $display("pass fib(10) = 55");
      $display("ALL TESTS PASSED");
    end else
      $display("FAIL fib(10): got=%0d expected=55", dut.rf.regs[10]);
    $finish;
  end
endmodule