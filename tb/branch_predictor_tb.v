`timescale 1ns/1ps

module branch_predictor_tb;
  reg         clk = 0;
  reg         reset = 1;
  reg  [31:0] pc = 0;
  reg         update = 0;
  reg  [31:0] update_pc = 0;
  reg         actual_taken = 0;
  reg  [31:0] actual_target = 0;
  wire        pred_taken;
  wire [31:0] pred_target;
  integer errors = 0;

  branch_predictor dut (
    .clk(clk), .reset(reset),
    .pc(pc), .pred_taken(pred_taken), .pred_target(pred_target),
    .update(update), .update_pc(update_pc),
    .actual_taken(actual_taken), .actual_target(actual_target)
  );

  always #5 clk = ~clk;

  // tell the predictor what a branch did
  task train(input [31:0] bpc, input taken, input [31:0] tgt);
    begin
      update = 1; update_pc = bpc; actual_taken = taken; actual_target = tgt;
      @(posedge clk); #1;
      update = 0;
    end
  endtask

  // ask for a prediction and check it
  task check(input [8*14-1:0] name, input [31:0] at_pc,
             input exp_taken, input [31:0] exp_target);
    begin
      pc = at_pc; #1;
      if (pred_taken !== exp_taken || (exp_taken && pred_target !== exp_target)) begin
        $display("FAIL %0s: got taken=%b target=%h expected taken=%b target=%h",
                 name, pred_taken, pred_target, exp_taken, exp_target);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    @(posedge clk); #1;
    reset = 0;

    check("cold_miss",      32'h40, 0, 0);            // never seen: predict not taken

    train(32'h40, 1, 32'h10);
    check("learned",        32'h40, 1, 32'h10);       // weakly taken now

    train(32'h40, 1, 32'h10);                          // strongly taken
    train(32'h40, 0, 32'h10);                          // one surprise...
    check("hysteresis",     32'h40, 1, 32'h10);       // ...still predicts taken

    train(32'h40, 0, 32'h10);                          // second not taken
    check("flipped",        32'h40, 0, 0);

    train(32'h80, 1, 32'h200);                         // same slot as 0x40, different branch
    check("tag_mismatch",   32'h40, 0, 0);            // 0x40 got replaced
    check("new_owner",      32'h80, 1, 32'h200);

    train(32'h80, 1, 32'h300);                         // like jalr: new target
    check("new_target",     32'h80, 1, 32'h300);

    train(32'h24, 0, 32'h0);                           // not taken, never seen
    check("no_alloc",       32'h24, 0, 0);            // not added to the table

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule