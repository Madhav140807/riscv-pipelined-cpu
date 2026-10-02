`timescale 1ns/1ps

module pipe_perf_tb;
  reg clk = 0;
  reg reset = 1;
  integer errors = 0;

  wire        halted;
  wire [31:0] cycles, instret, stalls, flushes;

  cpu_pipe #(.IMEM_FILE("programs/bench_sum.hex")) dut (
    .clk(clk), .reset(reset), .halted(halted),
    .cycle_count(cycles), .instret_count(instret),
    .stall_count(stalls), .flush_count(flushes)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("sim/pipe_perf.vcd");
    $dumpvars(0, pipe_perf_tb);
  end

  // give up if the CPU never halts
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

    check("sum",     dut.rf.regs[4],   32'd55);
    check("mem[16]", dut.dmem.mem[16], 32'd55);
    check("instret", instret,          32'd87);
    check("stalls",  stalls,           32'd10);
    check("flushes", flushes,          32'd18);
    check("cycles",  cycles,           32'd137);

    $display("CPI = %0.3f", cycles * 1.0 / instret);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule