module stimulus_gen (input clk, output reg [7:0] d, output reg reset);

  // Signals
  logic [7:0] data_counter;

  // Initialize reset and data_counter
  initial begin
    reset = 1'b1;
    data_counter = 8'd0;
  end

  // Generate reset after some time
  initial begin
    #10 reset = 1'b0;
  end

  // Update data every 25ms (25ms * 5ns per # unit implies #5000 for 25ms if clock is 50MHz, but adjust as needed)
  always #25_000 begin // Adjust the time as necessary for real simulation timing
    if (data_counter < 8'd255) begin
      data_counter <= data_counter + 1;
    end else begin
      data_counter <= 8'd0;
    end
  end

  // Assign d to data_counter
  always @(*) begin
    d = data_counter;
  end

  // Keep d as reg with blocking assignments? Wait: d is assigned via always @* but declared as reg. If using in procedural assignments, no. Alternatively use continuous assignment. Wait: if using procedural assignment, use always_ff. But given the current setup, perhaps data_counter is updated with non-blocking, d is combinational.
  // Wait: the code above has data_counter updated in an always block with # delays. Then d is assigned via always @* to data_counter. But since data_counter is updated via blocking assignments (using <= in the always block), that may work. Need to ensure d is updated when data_counter changes.

endmodule