module TopModule (input logic clk, input logic reset, output logic [7:0] out);
  logic [2:0] state;
  localparam STATE_A = 3'd0,
             STATE_B = 3'd1,
             STATE_C = 3'd2,
             STATE_D = 3'd3;

  initial begin
    state = STATE_A;
  end

  always @(posedge clk) begin
    if (reset) begin
      state <= STATE_A;
    end else begin
      case (state)
        STATE_A: state <= STATE_B;
        STATE_B: state <= STATE_C;
        STATE_C: state <= STATE_D;
        STATE_D: state <= STATE_A;
        default: state <= STATE_A;
      endcase
    end
  end

  logic [7:0] count;
  always @(*) begin
    count = 0;
  end

  assign out = count;
endmodule