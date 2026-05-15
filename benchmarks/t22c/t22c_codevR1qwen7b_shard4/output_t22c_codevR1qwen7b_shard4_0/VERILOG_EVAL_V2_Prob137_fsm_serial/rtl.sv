module TopModule (input clk, input reset, input in, output done);
  logic [2:0] state, next_state;
  logic [3:0] counter;
  logic [7:0] data_reg;
  logic done_reg;
  localparam IDLE = 3'b000,
            START = 3'b001,
            DATA = 3'b010,
            STOP = 3'b011,
            ERROR = 3'b100;

  // State register
  always @(posedge clk) begin
    if (reset) state <= IDLE;
    else state <= next_state;
  end

  // Data and counter registers
  always @(posedge clk) begin
    if (reset) begin
      data_reg <= 8'h0;
      counter <= 4'h0;
      done_reg <= 0;
    end else begin
      if (state == DATA) begin
        data_reg <= {in, data_reg[7:1]}; // LSB first
        counter <= counter + 1;
      end else if (state == STOP) begin
        counter <= 0;
        if (in) done_reg <= 1;
        else done_reg <= 0; // Stop error
      end else begin
        data_reg <= data_reg;
        counter <= 0;
        done_reg <= 0;
      end
    end
  end

  // Next state logic
  always @(*) begin
    next_state = state;
    case (state)
      IDLE: next_state = (in == 0) ? START : IDLE;
      START: next_state = (counter == 4'd9) ? DATA : START;
      DATA: next_state = (counter == 4'd8) ? STOP : DATA;
      STOP: next_state = (in == 1) ? IDLE : ERROR;
      ERROR: next_state = (in == 1) ? IDLE : ERROR;
      default: next_state = IDLE;
    endcase
  end

  // Done output
  assign done = done_reg;

endmodule