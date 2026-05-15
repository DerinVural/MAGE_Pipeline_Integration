```systemverilog
module stimulus_gen (
	input clk,
	output logic in1, in2, in3
);

	randomize(in1, in2, in3);
	repeat(100) @(posedge clk, negedge clk) begin
		{in1, in2, in3} <= $random;
	end
	#1 $finish;
endmodule

module tb();
	logic clk = 0;
	initial forever
		#5 clk = ~clk;

	logic in1, in2, in3;
	logic out_ref;
	logic out_dut;
	wire tb_match;

	stimulus_gen stim1 (
		.clk(clk),
		.*,
		.in1,
		.in2,
		.in3
	);
	RefModule good1 (
		.in1,
		.in2,
		.in3,
		.out(out_ref)
	);
	TopModule top_module1 (
		.in1,
		.in2,
		.in3,
		.out(out_dut)
	);

	assign tb_match = (out_ref == out_dut);

	integer errors = 0;
	integer errortime;

	always @(posedge clk, negedge clk) begin
		if (!tb_match) begin
			if (errors == 0) errortime = $time;
			errors++;
		end
	end

	initial begin
		$monitor("At time %t, in1=%b, in2=%b, in3=%b, ref=%b, dut=%b", $time, in1, in2, in3, out_ref, out_dut);
		#1000000 $finish;
	end

	final begin
		if (errors) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", errors, errortime);
		end else begin
			$display("SIMULATION PASSED");
		end
	end
endmodule
```
Note: The `RefModule` is assumed to be defined elsewhere in the project.