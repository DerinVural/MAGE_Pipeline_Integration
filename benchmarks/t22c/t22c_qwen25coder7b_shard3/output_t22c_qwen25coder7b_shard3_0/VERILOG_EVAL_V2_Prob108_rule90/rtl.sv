module TopModule (
  input logic clk,
  input logic load,
  input logic [511:0] data,
  output logic [511:0] q
);

  // Initialize the shift register with zero values
  logic [511:0] shift_reg;
  initial begin
    shift_reg = 0;
  end

  // Shift the register on every rising edge of the clock
  always @(posedge clk) begin
    if (load) begin
      // Load the new data into the shift register
      shift_reg <= data;
    end else begin
      // Apply Rule 90: XOR of neighboring cells
      if (load) begin
  // Load the new data into the shift register
  shift_reg <= data;
end else begin
  // Apply Rule 90: XOR of neighboring cells
  shift_reg <= {shift_reg[510] ^ shift_reg[511], shift_reg[511:1], shift_reg[0] ^ shift_reg[1]};
end
    end
  end

  // Assign the updated state to the output
  assign q = shift_reg;

endmodule