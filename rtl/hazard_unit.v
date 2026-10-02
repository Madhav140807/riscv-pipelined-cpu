module hazard_unit (
  input  wire       id_ex_mem_read,   // instruction in EX is a load
  input  wire [4:0] id_ex_rd,         // the register it loads into
  input  wire [4:0] id_rs1,           // what the instruction in ID reads
  input  wire [4:0] id_rs2,
  output wire       stall
);

  assign stall = id_ex_mem_read && (id_ex_rd != 5'd0) &&
                 ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2));

endmodule