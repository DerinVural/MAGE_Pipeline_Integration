module TopModule (
	clk,
	areset,
	d,
	q
);
	input clk;
	input areset;
	input [7:0] d;
	output reg [7:0] q;
endmodule