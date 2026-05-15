module TopModule(clk, resetn, x, y, f, g);
  input logic clk;
  input logic resetn;
  input logic x;
  input logic y;
  output logic f;
  output logic g;

  // Define states
  localparam STATE_A = 2'b00;
  localparam STATE_B = 2'b01;
  localparam STATE_C = 2'b10;
  localparam STATE_D = 2'b11;

  // State register
  logic [1:0] state;

  // Initialize state register
  initial begin
    state = STATE_A;
  end

  // Next state logic
  always @(posedge clk or negedge resetn) begin
    if (!resetn)
      state <= STATE_A;
    else begin
      case (state)
        STATE_A: state <= (x && !y) ? STATE_B : STATE_A;
        STATE_B: state <= (x && !y) ? STATE_C : STATE_A;
        STATE_C: state <= (x && !y) ? STATE_D : STATE_A;
        STATE_D: state <= y ? STATE_D : STATE_A;
      endcase
    end
  end

  // Output logic
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      f <= 0;
      g <= 0;
    end else begin
      case (state)
        STATE_A: begin
          f <= 0;
          g <= 0;
        end
        STATE_B: begin
          f <= 1;
          g <= 0;
        end
        STATE_C: begin
          f <= 1;
          g <= 1;
        end
        STATE_D: begin
          f <= 1;
          g <= (y) ? 1 : 0;
        end
      endcase
    end
  end
endmodule