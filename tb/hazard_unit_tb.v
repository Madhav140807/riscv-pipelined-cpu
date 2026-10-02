`timescale 1ns/1ps

module hazard_unit_tb;
  reg        id_ex_mem_read;
  reg  [4:0] id_ex_rd, id_rs1, id_rs2;
  wire       stall;
  integer errors = 0;

  hazard_unit dut (.id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd),
                   .id_rs1(id_rs1), .id_rs2(id_rs2), .stall(stall));

  task check(input [8*12-1:0] name, input mr, input [4:0] rd,
             input [4:0] rs1, input [4:0] rs2, input expected);
    begin
      id_ex_mem_read = mr; id_ex_rd = rd; id_rs1 = rs1; id_rs2 = rs2;
      #1;
      if (stall !== expected) begin
        $display("FAIL %0s: got=%b expected=%b", name, stall, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    //    name          load rd  rs1 rs2  stall?
    check("use_rs1",     1,  2,  2,  5,   1);
    check("use_rs2",     1,  2,  5,  2,   1);
    check("no_match",    1,  2,  3,  4,   0);
    check("not_load",    0,  2,  2,  2,   0);
    check("load_x0",     1,  0,  0,  0,   0);

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule