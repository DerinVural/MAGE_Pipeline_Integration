interface io_interface (
	logic clk,
	logic load,
	logic [1:0] ena,
	logic [99:0] data,
	logic [99:0] q
);