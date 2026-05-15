module TopModule (input logic clk, input logic d, output logic q);

  logic prev_clk;
  logic q0, q1;

  // Detect edges
  always @(clk) begin
    prev_clk <= clk;
  end

  // Update on both edges
  always @(*) begin
    if (clk != prev_clk) begin
      q <= d;
    end
  end

endmodule