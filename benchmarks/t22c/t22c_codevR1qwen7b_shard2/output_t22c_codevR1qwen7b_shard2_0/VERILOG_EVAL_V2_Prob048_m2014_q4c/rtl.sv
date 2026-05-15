module TopModule (clk, d, r, q);
  input logic clk;
  input logic d;
  input logic r;
  output logic q;

  always @(posedge clk) begin
    if (r)
      q <= 0;
    else
      q <= d;
  end
endmodule