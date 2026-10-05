`timescale 1ns/1ps
`include "defines.vh"

module alu_tb;
  reg  [31:0] a, b;
  reg  [3:0]  alu_ctrl;
  wire [31:0] result;
  integer errors = 0;


  alu dut (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result));

  task check(input [31:0] ta, input [31:0] tb_, input [3:0] op,
             input [31:0] expected, input [8*8-1:0] name);
    begin
      a = ta; b = tb_; alu_ctrl = op;
      #1;
      if (result !== expected) begin
        $display("FAIL %0s: a=%h b=%h got=%h expected=%h",
                 name, ta, tb_, result, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    check(32'd5,        32'd3,        `ALU_ADD,  32'd8,        "ADD");
    check(32'hFFFFFFFF, 32'd1,        `ALU_ADD,  32'd0,        "ADD_wrap");
    check(32'd3,        32'd5,        `ALU_SUB,  32'hFFFFFFFE, "SUB_neg");
    check(32'd1,        32'd4,        `ALU_SLL,  32'd16,       "SLL");
    check(32'd1,        32'd36,       `ALU_SLL,  32'd16,       "SLL_5bit");
    check(32'hFFFFFFFF, 32'd1,        `ALU_SLT,  32'd1,        "SLT");
    check(32'hFFFFFFFF, 32'd1,        `ALU_SLTU, 32'd0,        "SLTU");
    check(32'hF0F0F0F0, 32'h0F0F0F0F, `ALU_XOR,  32'hFFFFFFFF, "XOR");
    check(32'h80000000, 32'd4,        `ALU_SRL,  32'h08000000, "SRL");
    check(32'h80000000, 32'd4,        `ALU_SRA,  32'hF8000000, "SRA");
    check(32'hF0F0F0F0, 32'h0F0F0F0F, `ALU_OR,   32'hFFFFFFFF, "OR");
    check(32'hF0F0F0F0, 32'hFF00FF00, `ALU_AND,  32'hF000F000, "AND");

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule