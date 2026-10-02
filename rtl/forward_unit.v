`include "defines.vh"

module forward_unit (
  input  wire [4:0] id_ex_rs1,
  input  wire [4:0] id_ex_rs2,
  input  wire [4:0] ex_mem_rd,
  input  wire       ex_mem_reg_write,
  input  wire [4:0] mem_wb_rd,
  input  wire       mem_wb_reg_write,
  output reg  [1:0] fwd_a,
  output reg  [1:0] fwd_b
);

  always @(*) begin
    // newest value wins, so check EX/MEM first
    if (ex_mem_reg_write && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs1)
      fwd_a = `FWD_MEM;
    else if (mem_wb_reg_write && mem_wb_rd != 5'd0 && mem_wb_rd == id_ex_rs1)
      fwd_a = `FWD_WB;
    else
      fwd_a = `FWD_NONE;

    if (ex_mem_reg_write && ex_mem_rd != 5'd0 && ex_mem_rd == id_ex_rs2)
      fwd_b = `FWD_MEM;
    else if (mem_wb_reg_write && mem_wb_rd != 5'd0 && mem_wb_rd == id_ex_rs2)
      fwd_b = `FWD_WB;
    else
      fwd_b = `FWD_NONE;
  end

endmodule