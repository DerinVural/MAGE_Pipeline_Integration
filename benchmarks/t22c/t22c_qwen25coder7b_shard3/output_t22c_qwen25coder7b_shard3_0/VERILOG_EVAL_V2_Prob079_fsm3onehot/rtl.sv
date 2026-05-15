module TopModule (
  input  logic in,
  input  logic [3:0] state,
  output logic [3:0] next_state,
  output logic out
);

  localparam STATE_A = 4'b0001;
  localparam STATE_B = 4'b0010;
  localparam STATE_C = 4'b0100;
  localparam STATE_D = 4'b1000;

  // State transition logic
  always @(*) begin
    case (state)
      STATE_A: next_state = (in == 1'b0) ? STATE_B : STATE_A;
      STATE_B: next_state = (in == 1'b0) ? STATE_C : STATE_B;
      STATE_C: next_state = (in == 1'b0) ? STATE_A : STATE_D;
      STATE_D: next_state = (in == 1'b0) ? STATE_C : STATE_B;
      default: next_state = STATE_A; // Default state
    endcase
  end

  // Output logic
  always @(*) begin
    case (state)
      STATE_A: out = 1'b0;
      STATE_B: out = 1'b0;
      STATE_C: out = 1'b0;
      STATE_D: out = 1'b1;
      default: out = 1'b0; // Default output
    endcase
  end

endmodule