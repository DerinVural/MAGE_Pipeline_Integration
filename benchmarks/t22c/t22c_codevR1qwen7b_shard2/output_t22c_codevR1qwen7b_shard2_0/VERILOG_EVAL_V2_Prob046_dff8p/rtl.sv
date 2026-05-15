module TopModule (input logic clk, input logic reset, input logic [7:0] d, output logic [7:0] q);
  reg [7:0] q_reg;
  always @(negedge clk) begin
    if (reset)
      q_reg <= 8'h34;
    else
      q_reg <= d;
  end
  assign q = q_reg;
endmodule