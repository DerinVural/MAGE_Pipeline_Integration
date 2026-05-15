module TopModule (input logic clk, input logic load, input logic [511:0] data, output logic [511:0] q);

  logic [511:0] next_q;
  logic [511:0] q_reg;

  initial begin
    next_q = 0;
    q_reg = 0;
  end

  // Combinational logic for next state
  always @(*) begin
    integer i;
    for (i = 0; i < 512; i++) begin
      logic left;
      logic center;
      logic right;
      left = (i == 0) ? 1'b0 : q_reg[i-1];
      center = q_reg[i];
      right = (i == 511) ? 1'b0 : q_reg[i+1];

      case ({left, center, right})
        3'b111: next_q[i] = 0;
        3'b110: next_q[i] = 1;
        3'b101: next_q[i] = 1;
        3'b100: next_q[i] = 0;
        3'b011: next_q[i] = 1;
        3'b010: next_q[i] = 1;
        3'b001: next_q[i] = 1;
        3'b000: next_q[i] = 0;
        default: next_q[i] = 0;
      endcase
    end
  end

  // Sequential logic with load
  always @(posedge clk) begin
    if (load)
      q_reg <= data;
    else
      q_reg <= next_q;
  end

  assign q = q_reg;

endmodule