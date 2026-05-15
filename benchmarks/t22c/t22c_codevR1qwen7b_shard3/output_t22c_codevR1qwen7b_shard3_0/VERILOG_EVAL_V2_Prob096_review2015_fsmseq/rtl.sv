module TopModule (clk, reset, data, start_shifting);
  input logic clk;
  input logic reset;
  input logic data;
  output logic start_shifting;

  // States
  localparam IDLE  = 3'b000;
  localparam S1    = 3'b001;
  localparam S2    = 3'b010;
  localparam S3    = 3'b011;
  localparam MATCH = 3'b100;

  logic [2:0] current_state, next_state;
  logic start_reg;

  // State register
  always @(posedge clk) begin
    if (reset) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // Next state logic
  always @(*) begin
    case (current_state)
      IDLE: begin
        next_state = data ? S1 : IDLE;
      end
      S1: begin
        next_state = data ? S2 : IDLE;
      end
      S2: begin
        next_state = data ? S3 : S1;
      end
      S3: begin
        next_state = data ? MATCH : IDLE;
      end
      MATCH: begin
        next_state = MATCH; // Stay until reset
      end
      default: next_state = IDLE;
    endcase
  end

  // Output logic
  always @(posedge clk) begin
    if (reset) begin
      start_reg <= 0;
    end else if (current_state == S3 && data) begin
      start_reg <= 1;
    end
  end

  assign start_shifting = start_reg;

  // Initialize start_reg and state to IDLE
  initial begin
    current_state = IDLE;
    start_reg = 0;
  end

endmodule