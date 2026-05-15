module TopModule (clk, reset, in, out);
  input logic clk;
  input logic reset;
  input logic in;
  output logic out;

  // Define states
  localparam STATE_A = 2'b00;
  localparam STATE_B = 2'b01;
  localparam STATE_C = 2'b10;
  localparam STATE_D = 2'b11;

  // Declare state registers and next state variable
  logic [1:0] state;
  logic [1:0] next_state;

  // Initialize state registers
  initial begin
    state = STATE_A;
  end

  // Sequential block for state transition with synchronous reset
  always @(posedge clk) begin
    if (reset)
      state <= STATE_A;
    else
      state <= next_state;
  end

  // Combinational logic for next state and output
  always @(*) begin
    case (state)
      STATE_A: begin
        if (in) next_state = STATE_B;
        else next_state = STATE_A;
        out = 0;
      end
      STATE_B: begin
        if (in) next_state = STATE_C;
        else next_state = STATE_B;
        out = 0;
      end
      STATE_C: begin
        if (in) next_state = STATE_D;
        else next_state = STATE_A;
        out = 0;
      end
      STATE_D: begin
        if (in) next_state = STATE_B;
        else next_state = STATE_C;
        out = 1;
      end
      default: begin
        next_state = STATE_A;
        out = 0;
      end
    endcase
  end
endmodule