`timescale 1ns/1ps

module instr_mem_tb;
  reg  [31:0] addr;
  wire [31:0] instr;
  integer errors = 0;

  instr_mem #(.WORDS(16), .INIT_FILE("tb/imem_test.hex"))
    dut (.addr(addr), .instr(instr));

  task check(input [8*10-1:0] name, input [31:0] a, input [31:0] expected);
    begin
      addr = a; #1;
      if (instr !== expected) begin
        $display("FAIL %0s: addr=%h got=%h expected=%h",
                 name, a, instr, expected);
        errors = errors + 1;
      end else
        $display("pass %0s", name);
    end
  endtask

  initial begin
    check("addr_0",    32'd0,  32'h00A08293);
    check("addr_4",    32'd4,  32'h FFF08293);
    check("addr_8",    32'd8,  32'h0020A423);
    check("nop_fill",  32'd12, 32'h00000013);  // past end of file
    check("low_bits",  32'd5,  32'hFFF08293);  // bottom 2 bits ignored

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
endmodule