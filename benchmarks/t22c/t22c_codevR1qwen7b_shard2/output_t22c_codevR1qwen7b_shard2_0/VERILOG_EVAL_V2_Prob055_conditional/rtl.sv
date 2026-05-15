module TopModule (input logic [7:0] a, input logic [7:0] b, input logic [7:0] c, input logic [7:0] d, output logic [7:0] min);

  logic [7:0] min_ab, min_cd;

  // Compare a and b, take smaller
  always @(*) begin
    min_ab = (a < b) ? a : b;
  end

  // Compare c and d, take smaller
  always @(*) begin
    min_cd = (c < d) ? c : d;
  end

  // Compare the two minima
  always @(*) begin
    min = (min_ab < min_cd) ? min_ab : min_cd;
  end

endmodule