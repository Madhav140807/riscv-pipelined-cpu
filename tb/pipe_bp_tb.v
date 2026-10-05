`timescale 1ns/1ps

module pipe_bp_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;

  wire        halted;
  wire [31:0] cycles, instret, stalls, flushes, branches;

  cpu_pipe #(.IMEM_FILE("programs/bench_sum.hex"), .USE_BP(1)) dut (
    .clk(clk), .reset(reset), .halted(halted),
    .cycle_count(cycles), .instret_count(instret),
    .stall_count(stalls), .flush_count(flushes), .branch_count(branches)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/pipe_bp.vcd");
    $dumpvars(0, pipe_bp_tb);
  end

  initial begin
    #20000;
    $display("FAIL timeout: CPU never halted");
    $finish;
  end

  task check(input [8*10-1:0] name, input [31:0] got, input [31:0] expected);
    begin
      if (got !== expected) begin
        $display("FAIL %0s: got=%0d expected=%0d", name, got, expected);
        errors = errors + 1;
      end else
        $display("pass %0s = %0d", name, got);
    end
  endtask

  initial begin
    @(posedge clk); #1;
    reset = 0;

    wait (halted);
    repeat (5) @(posedge clk);
    #1;

    check("sum",      dut.rf.regs[4], 32'd55);
    check("instret",  instret,        32'd87);
    check("branches", branches,       32'd20);
    check("flushes",  flushes,        32'd4);    // was 18 without prediction
    check("cycles",   cycles,         32'd109);  // was 137 without prediction

    $display("CPI = %0.3f (was 1.575)", cycles * 1.0 / instret);
    $display("prediction accuracy = %0.1f%%", 100.0 * (branches - flushes) / branches);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule