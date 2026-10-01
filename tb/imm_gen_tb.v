`timescale 1ns/1ps

module imm_gen_tb;
  reg  [31:0] instr;
  wire [31:0] imm;
  integer errors = 0;

  imm_gen dut (.instr(instr), .imm(imm));

  task check(input [31:0] in, input [31:0] expected,
             input [8*10-1:0] name);
    begin
      instr = in; #1;
      if (imm !== expected) begin
        $display("FAIL %0s: instr=%h got=%h expected=%h",
                 name, in, imm, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    // I type
    check(32'h00A08293, 32'h0000000A, "addi_pos");  // addi x5, x1, 10
    check(32'hFFF08293, 32'hFFFFFFFF, "addi_neg");  // addi x5, x1, -1

    // S type
    check(32'h0020A423, 32'h00000008, "sw_pos");    // sw x2, 8(x1)
    check(32'hFE20AE23, 32'hFFFFFFFC, "sw_neg");    // sw x2, -4(x1)

    // B type
    check(32'h00208863, 32'h00000010, "beq_pos");   // beq x1, x2, 16
    check(32'hFE208CE3, 32'hFFFFFFF8, "beq_neg");   // beq x1, x2, -8
    check(32'h002080E3, 32'h00000800, "beq_b11");   // beq x1, x2, 2048

    // U type
    check(32'h123452B7, 32'h12345000, "lui");       // lui x5, 0x12345

    // J type
    check(32'h008000EF, 32'h00000008, "jal_pos");   // jal x1, 8
    check(32'hFFDFF0EF, 32'hFFFFFFFC, "jal_neg");   // jal x1, -4
    check(32'h001000EF, 32'h00000800, "jal_b11");   // jal x1, 2048

    // R type: no immediate
    check(32'h002081B3, 32'h00000000, "r_type");    // add x3, x1, x2

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule