`timescale 1ns/1ps
`include "defines.vh"

module branch_unit_tb;
  reg         branch;
  reg  [2:0]  funct3;
  reg  [31:0] a, b;
  wire        taken;
  integer errors = 0;

  branch_unit dut (.branch(branch), .funct3(funct3),
                   .a(a), .b(b), .taken(taken));

  task check(input [8*12-1:0] name, input br, input [2:0] f3,
             input [31:0] ta, input [31:0] tb_, input expected);
    begin
      branch = br; funct3 = f3; a = ta; b = tb_; #1;
      if (taken !== expected) begin
        $display("FAIL %0s: got=%b expected=%b", name, taken, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    //    name           br  funct3     a             b      taken?
    check("beq_equal",    1, `F3_BEQ,  32'd7,        32'd7,  1);
    check("beq_diff",     1, `F3_BEQ,  32'd7,        32'd8,  0);
    check("bne_diff",     1, `F3_BNE,  32'd7,        32'd8,  1);
    check("blt_neg",      1, `F3_BLT,  32'hFFFFFFFF, 32'd1,  1);  // -1 < 1
    check("bltu_big",     1, `F3_BLTU, 32'hFFFFFFFF, 32'd1,  0);  // 4 billion < 1? no
    check("bge_equal",    1, `F3_BGE,  32'd5,        32'd5,  1);  // >= includes equal
    check("bge_neg",      1, `F3_BGE,  32'hFFFFFFFF, 32'd1,  0);  // -1 >= 1? no
    check("bgeu_big",     1, `F3_BGEU, 32'hFFFFFFFF, 32'd1,  1);
    check("not_branch",   0, `F3_BEQ,  32'd7,        32'd7,  0);  // equal, but not a branch
    check("bad_funct3",   1, 3'b010,   32'd7,        32'd7,  0);  // invalid type

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule