module branch_predictor #(
  parameter ENTRIES = 16
) (
  input  wire        clk,
  input  wire        reset,

  // Predict: looked up in IF with the current PC
  input  wire [31:0] pc,
  output wire        pred_taken,
  output wire [31:0] pred_target,

  // Update: a branch or jump finished EX
  input  wire        update,
  input  wire [31:0] update_pc,
  input  wire        actual_taken,
  input  wire [31:0] actual_target
);

  localparam IW = $clog2(ENTRIES);

  // Branch target buffer: one entry per slot
  reg        valid   [0:ENTRIES-1];
  reg [31:0] tag     [0:ENTRIES-1];   // full PC of the branch stored here
  reg [31:0] target  [0:ENTRIES-1];   // where it jumped last time
  reg  [1:0] counter [0:ENTRIES-1];   // 2 bit confidence: 00, 01 = not taken; 10, 11 = taken

  // Predict
  wire [IW-1:0] idx = pc[IW+1:2];
  wire          hit = valid[idx] && (tag[idx] == pc);
  wire    [1:0] ctr = counter[idx];

  assign pred_taken  = hit && ctr[1];
  assign pred_target = target[idx];

  // Update
  wire [IW-1:0] uidx = update_pc[IW+1:2];
  wire          uhit = valid[uidx] && (tag[uidx] == update_pc);
  wire    [1:0] uctr = counter[uidx];

  integer i;
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < ENTRIES; i = i + 1)
        valid[i] <= 1'b0;
    end else if (update) begin
      if (uhit) begin
        if (actual_taken) begin
          if (uctr != 2'b11) counter[uidx] <= uctr + 2'd1;
          target[uidx] <= actual_target;
        end else begin
          if (uctr != 2'b00) counter[uidx] <= uctr - 2'd1;
        end
      end else if (actual_taken) begin
        // first time we see this branch taken: add it, weakly taken
        valid[uidx]   <= 1'b1;
        tag[uidx]     <= update_pc;
        target[uidx]  <= actual_target;
        counter[uidx] <= 2'b10;
      end
    end
  end

endmodule