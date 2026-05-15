module stimulus_gen (
	input clk,
	output logic [3:0] x,
	output logic [3:0] y
);
	random seed;
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{seed, x, y} <= $random;
		end
		#1 $finish;
	end
endmodule

module tb();
	logic [3:0] x;
	logic [3:0] y;
	logic [4:0] sum_ref;
	logic [4:0] sum_dut;

top_module top_module (
		.x,
		.y,
		.sum(sum_dut)
	);
endmodule