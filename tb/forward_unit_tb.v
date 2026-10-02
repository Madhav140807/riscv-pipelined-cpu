`timescale 1ns/1ps
`include "defines.vh"

module forward_unit_tb;
  reg  [4:0] id_ex_rs1, id_ex_rs2, ex_mem_rd, mem_wb_rd;
  reg        ex_mem_reg_write, mem_wb_reg_write;
  wire [1:0] fwd_a, fwd_b;
  integer errors = 0;

  forward_unit dut (
    .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2),
    .ex_mem_rd(ex_mem_rd), .ex_mem_reg_write(ex_mem_reg_write),
    .mem_wb_rd(mem_wb_rd), .mem_wb_reg_write(mem_wb_reg_write),
    .fwd_a(fwd_a), .fwd_b(fwd_b)
  );

  task check(input [8*12-1:0] name,
             input [4:0] rs1, input [4:0] rs2,
             input [4:0] m_rd, input m_we,
             input [4:0] w_rd, input w_we,
             input [1:0] exp_a, input [1:0] exp_b);
    begin
      id_ex_rs1 = rs1; id_ex_rs2 = rs2;
      ex_mem_rd = m_rd; ex_mem_reg_write = m_we;
      mem_wb_rd = w_rd; mem_wb_reg_write = w_we;
      #1;
      if (fwd_a !== exp_a || fwd_b !== exp_b) begin
        $display("FAIL %0s: got a=%b b=%b expected a=%b b=%b",
                 name, fwd_a, fwd_b, exp_a, exp_b);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    //    name          rs1 rs2  mem_rd we  wb_rd we  fwd_a      fwd_b
    check("no_match",    1,  2,   3,    1,  4,    1,  `FWD_NONE, `FWD_NONE);
    check("mem_to_a",    1,  2,   1,    1,  4,    1,  `FWD_MEM,  `FWD_NONE);
    check("wb_to_b",     1,  2,   3,    1,  2,    1,  `FWD_NONE, `FWD_WB);
    check("newest_wins", 1,  2,   1,    1,  1,    1,  `FWD_MEM,  `FWD_NONE);
    check("both_srcs",   5,  5,   5,    1,  0,    0,  `FWD_MEM,  `FWD_MEM);
    check("x0_never",    0,  0,   0,    1,  0,    1,  `FWD_NONE, `FWD_NONE);
    check("no_write",    1,  2,   1,    0,  2,    0,  `FWD_NONE, `FWD_NONE);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule