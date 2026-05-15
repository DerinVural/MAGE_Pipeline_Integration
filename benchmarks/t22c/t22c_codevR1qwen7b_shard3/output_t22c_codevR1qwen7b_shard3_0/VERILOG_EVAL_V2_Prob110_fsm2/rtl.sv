module TopModule(clk, areset, j, k, out);
  input clk;
  input areset;
  input j;
  input k;
  output logic out;

  // Define states
  localparam STATE_OFF = 1'b0;
  localparam STATE_ON  = 1'b1;

  // State registers
  logic state;
  logic next_state;

  // State register without reset: initial value set via initial block
  always @(posedge clk, posedge areset) begin
    if (areset) state <= STATE_OFF;
    else state <= next_state;
  end

  // Next state logic
  always @(*) begin
    case (state)
      STATE_OFF: next_state = j ? STATE_ON : STATE_OFF;
      STATE_ON:  next_state = k ? STATE_OFF : STATE_ON;
      default: next_state = STATE_OFF;
    endcase
  end

  // Output logic
  always @(*) begin
    out = (state == STATE_OFF) ? 1'b0 : 1'b1;
  end

  // Initialize state
  initial begin
    state = STATE_OFF;
  end

endmodule