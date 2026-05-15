module stimulus_gen (
	input clk,
	output logic [7:0] a, b,
	passive wire[511:0] wavedrom_title,
	passive wire wavedrom_enable	
);

	// Task declarations...

	initial begin
		{a, b} <= 0;
		@(negedge clk) wavedrom_start();
		// Clock toggling and data assignment...
		$finish;
	end

endmodule

module tb();
	// Typedef and statistics declaration...

	typedef struct packed {
		int errors;
		int errortime;
		int errors_s;
		int errortime_s;
		int errors_overflow;
		int errortime_overflow;
		int clocks;
	} stats;

	stats stats1;

	// Wavedrom variables...

	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [7:0] a;
	logic [7:0] b;
	logic [7:0] s_ref;
	logic [7:0] s_dut;
	logic overflow_ref;
	logic overflow_dut;

	// Stimulus generation and reference module instantiation...

	stimulus_gen stim1 (
		.clk,
		.*,
		.a,
		.b );
	RefModule good1 (
		.a,
		.b,
		.s(s_ref),
		.overflow(overflow_ref) );
	
	TopModule top_module1 (
		.a,
		.b,
		.s(s_dut),
		.overflow(overflow_dut) );

	// Matching and error counting logic...

	assign tb_match = ( { s_ref, overflow_ref } === ( { s_ref, overflow_ref } ^ { s_dut, overflow_dut } ^ { s_ref, overflow_ref } ) );
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (s_ref !== ( s_ref ^ s_dut ^ s_ref )) begin
			if (stats1.errors_s == 0) stats1.errortime_s = $time;
			stats1.errors_s++;
		end
		if (overflow_ref !== ( overflow_ref ^ overflow_dut ^ overflow_ref )) begin
			if (stats1.errors_overflow == 0) stats1.errortime_overflow = $time;
			stats1.errors_overflow++;
		end
	end

	// Simulation completion and results display...

	final begin
		if (stats1.errors_s) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "s", stats1.errors_s, stats1.errortime_s);
		else $display("Hint: Output '%s' has no mismatches.", "s");
		if (stats1.errors_overflow) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "overflow", stats1.errors_overflow, stats1.errortime_overflow);
		else $display("Hint: Output '%s' has no mismatches.", "overflow");
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors, stats1.errortime);
		end
	end

	// Timeout handling...

	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule

