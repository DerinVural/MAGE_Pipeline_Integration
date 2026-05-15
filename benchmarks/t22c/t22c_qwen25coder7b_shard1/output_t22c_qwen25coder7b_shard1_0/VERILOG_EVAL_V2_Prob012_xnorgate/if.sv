module tb;
	logic clk;
	logic a;
	logic b;
	logic out_ref;
	logic out_dut;
	wire tb_match;
	wire tb_mismatch;
	stimulus_gen stim1 (
		.clk,
		.*,
		a,
		b);
	RefModule good1 (
		a,
		b,
		.out(out_ref));
	TopModule top_module1 (
		.a,
		.b,
		.out(out_dut));
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	initial begin
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, a, b, out_ref, out_dut);
	end
	always @(posedge clk, negedge clk) begin
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; end
	end
	final begin
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
endmodule