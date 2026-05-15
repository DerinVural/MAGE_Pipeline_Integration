module stimulus_gen (
	input clk,
	output logic x,
	output logic y
);

	always @(posedge clk)
		{ x, y } <= $random % 2;

	initial begin
		repeat(101) @(negedge clk);
		#1 $finish;
	end

endmodule

module tb();
	logic clk;
	logic x;
	logic y;
	logic z_ref;
	logic z_dut;

	stimulus_gen stim1 (
		.clk(clk),
		.x(x),
		.y(y)
	);

	RefModule good1 (
		.x(x),
		.y(y),
		.z(z_ref)
	);

	TopModule top_module1 (
		.x(x),
		.y(y),
		.z(z_dut)
	);

	final begin
		if (z_dut != z_ref) $display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %t", $time);
		else $display("SIMULATION PASSED");
	end

endmodule