interface io_interface (
  input clk,
  input load,
  input [511:0] data,
  output reg [511:0] q
);
endinterface