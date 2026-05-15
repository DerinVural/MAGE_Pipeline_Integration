module TopModule (input logic clk, input logic a, output logic [2:0] q);

  // Initialize q to 0 to avoid X
  logic [2:0] state = 0;
  logic [1:0] a_delay;

  // Delay a by two clocks to detect edges
  always @(posedge clk) begin
    a_delay <= {a_delay[0], a};
  end

  // Increment state when a falls from 1 to 0
  always @(posedge clk) begin
    if (a_delay == 2'b10) begin // posedge to negedge transition
      state <= state + 1;
    end else if (a) begin // a remains 1, increment after initial phase
      if (state >= 4) begin
        state <= 0;
      end else begin
        state <= state + 1;
      end
    end else if (state == 5) begin // Example state for reset
      state <= 0;
    end
  end

  assign q = state;

endmodule