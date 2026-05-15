module TopModule (input clk, input x, input [2:0] y, output Y0, output z);
  logic [2:0] state;
  logic [2:0] next_state;

  // State definitions
  localparam STATE_000 = 3'b000;
  localparam STATE_001 = 3'b001;
  localparam STATE_010 = 3'b010;
  localparam STATE_011 = 3'b011;
  localparam STATE_100 = 3'b100;

  // Initialize state to known value
  initial state = STATE_000;

  // Combinational logic for next state and output
  always @(*) begin
    case (state)
      STATE_000: next_state = x ? STATE_001 : STATE_000;
      STATE_001: next_state = x ? 3'b100 : STATE_001;
      STATE_010: next_state = x ? STATE_001 : STATE_010;
      STATE_011: next_state = x ? STATE_010 : STATE_001;
      STATE_100: next_state = x ? STATE_100 : STATE_011;
      default: next_state = STATE_000;
    endcase
  end

  // Combinational logic for output z
  assign z = (state == STATE_011 && !x) || (state == STATE_100 && x);
  assign Y0 = next_state[0];

  // Sequential block
  always @(posedge clk) begin
    state <= next_state;
  end
endmodule