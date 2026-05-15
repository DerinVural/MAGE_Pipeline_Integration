module tb;
	parameter INPUT_WIDTH = 1;
	parameter OUTPUT_WIDTH = 1;
	logic clk;
	logic reset;
	logic s;
	logic w;
	logic z_ref;
	logic z_dut;
	wire tb_match;

	stimulus_gen stim1 (
		.clk(clk),
		.reset,
		.s,
		.w );
	RefModule good1 (
		.clk(clk),
		.reset,
		.s,
		.w,
		.z(z_ref) );

	TopModule top_module1 (
		.clk(clk),
		.reset(reset),
		.s(s),
		.w(w),
		.z(z_dut)
	);

	assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

	initial begin
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, clk, reset, s, w, z_ref, z_dut);
		clk = 0;
		reset = 1;
		s = 0;
		w = 0;
		#10 reset = 0;
		repeat(200) @(posedge clk);
		reset = 1;
		#10 reset = 0;
		repeat(200) @(posedge clk);
		#10 $finish;
	end

	final begin
		if (stats1.errors_z) $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
		else $display("Hint: Output 'z' has no mismatches.");
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
	} stats;

	stats stats1;

	assign tb_mismatch = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
			stats1.errors_z = stats1.errors_z+1'b1; end
	end
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
endmodule