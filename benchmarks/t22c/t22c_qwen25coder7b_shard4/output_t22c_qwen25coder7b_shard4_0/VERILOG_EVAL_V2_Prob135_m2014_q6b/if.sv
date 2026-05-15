module tb;
	logic [2:0] y;
	logic w;
	logic Y1;
	logic Y1_ref;
	reg clk = 0;
	initial forever
		#5 clk = ~clk;
	signal y;
	signal w;
	assign Y1 = ...;
	assign Y1_ref = ...;
	module TopModule (
		.y,
		.w,
		.Y1);
	endmodule
endmodule