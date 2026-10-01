`ifndef DEFINES_VH
`define DEFINES_VH

// ALU operation codes = {funct7[5], funct3}
`define ALU_ADD  4'b0000
`define ALU_SUB  4'b1000
`define ALU_SLL  4'b0001
`define ALU_SLT  4'b0010
`define ALU_SLTU 4'b0011
`define ALU_XOR  4'b0100
`define ALU_SRL  4'b0101
`define ALU_SRA  4'b1101
`define ALU_OR   4'b0110
`define ALU_AND  4'b0111

`endif
// ALU input A select
`define A_RS1  2'b00
`define A_PC   2'b01
`define A_ZERO 2'b10

// ALU input B select
`define B_RS2  1'b0
`define B_IMM  1'b1

// Writeback select
`define RES_ALU 2'b00
`define RES_MEM 2'b01
`define RES_PC4 2'b10



// Opcodes (instr[6:0])
`define OP_LUI    7'b0110111
`define OP_AUIPC  7'b0010111
`define OP_JAL    7'b1101111
`define OP_JALR   7'b1100111
`define OP_BRANCH 7'b1100011
`define OP_LOAD   7'b0000011
`define OP_STORE  7'b0100011
`define OP_IMM    7'b0010011
`define OP_REG    7'b0110011