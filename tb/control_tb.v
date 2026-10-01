`timescale 1ns/1ps
`include "defines.vh"

module control_tb;
  reg  [31:0] instr;
  wire        reg_write, alu_src_b, mem_read, mem_write;
  wire        branch, jal, jalr;
  wire  [1:0] alu_src_a, result_src;
  wire  [3:0] alu_ctrl;
  integer errors = 0;

  control dut (
    .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7_5(instr[30]),
    .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
    .mem_read(mem_read), .mem_write(mem_write), .result_src(result_src),
    .branch(branch), .jal(jal), .jalr(jalr), .alu_ctrl(alu_ctrl)
  );

  // Compare all 15 control bits at once
  task check(input [8*14-1:0] name, input [31:0] in,
             input rw, input [1:0] a, input b, input mr, input mw,
             input [1:0] res, input br, input j, input jr,
             input [3:0] alu);
    reg [14:0] got, exp;
    begin
      instr = in; #1;
      got = {reg_write, alu_src_a, alu_src_b, mem_read, mem_write,
             result_src, branch, jal, jalr, alu_ctrl};
      exp = {rw, a, b, mr, mw, res, br, j, jr, alu};
      if (got !== exp) begin
        $display("FAIL %0s: got=%b expected=%b", name, got, exp);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    //    name             instr         rw  A        B       mr mw res       br j  jr alu
    check("add",           32'h002081B3, 1, `A_RS1,  `B_RS2, 0, 0, `RES_ALU, 0, 0, 0, `ALU_ADD);  // add x3, x1, x2
    check("sub",           32'h402081B3, 1, `A_RS1,  `B_RS2, 0, 0, `RES_ALU, 0, 0, 0, `ALU_SUB);  // sub x3, x1, x2
    check("addi_neg_trap", 32'hFFF08293, 1, `A_RS1,  `B_IMM, 0, 0, `RES_ALU, 0, 0, 0, `ALU_ADD);  // addi x5, x1, -1
    check("srai",          32'h4030D293, 1, `A_RS1,  `B_IMM, 0, 0, `RES_ALU, 0, 0, 0, `ALU_SRA);  // srai x5, x1, 3
    check("lw",            32'h0080A283, 1, `A_RS1,  `B_IMM, 1, 0, `RES_MEM, 0, 0, 0, `ALU_ADD);  // lw x5, 8(x1)
    check("sw",            32'h0020A423, 0, `A_RS1,  `B_IMM, 0, 1, `RES_ALU, 0, 0, 0, `ALU_ADD);  // sw x2, 8(x1)
    check("beq",           32'h00208863, 0, `A_RS1,  `B_RS2, 0, 0, `RES_ALU, 1, 0, 0, `ALU_ADD);  // beq x1, x2, 16
    check("jal",           32'h008000EF, 1, `A_RS1,  `B_RS2, 0, 0, `RES_PC4, 0, 1, 0, `ALU_ADD);  // jal x1, 8
    check("jalr",          32'h000280E7, 1, `A_RS1,  `B_IMM, 0, 0, `RES_PC4, 0, 0, 1, `ALU_ADD);  // jalr x1, 0(x5)
    check("lui",           32'h123452B7, 1, `A_ZERO, `B_IMM, 0, 0, `RES_ALU, 0, 0, 0, `ALU_ADD);  // lui x5, 0x12345
    check("auipc",         32'h00001297, 1, `A_PC,   `B_IMM, 0, 0, `RES_ALU, 0, 0, 0, `ALU_ADD);  // auipc x5, 0x1
    check("all_zero",      32'h00000000, 0, `A_RS1,  `B_RS2, 0, 0, `RES_ALU, 0, 0, 0, `ALU_ADD);  // invalid

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule