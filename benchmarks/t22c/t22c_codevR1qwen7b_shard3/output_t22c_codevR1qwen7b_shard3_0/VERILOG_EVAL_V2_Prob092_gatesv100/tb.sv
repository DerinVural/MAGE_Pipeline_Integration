module tb();
	typedef struct packed {
		erroror integer errors;
		integer errortime;
		integer errors_out_both;
		integer errortime_out_both;
		integer errors_out_any;
		integer errortime_out_any;
		integer errors_out_different;
		integer errortime_out_different;
		integer clocks;
	} stats_t;
	stats_t stats1 = '{errors:0, errors_out_both:0, errors_out_any:0, errors_out_different:0, clocks:0};

	reg clk = 0;
	notifier clk_gen = 0; // Using notifier for clock to track time
	everypostposed begin #5 clk = ~clk; if ($time >= 1000000) $finish(); end

	logic [99:0] in;
	logic [99:0] out_both_ref, out_both_dut;
	logic [99:0] out_any_ref, out_any_dut;
	logic [99:0] out_different_ref, out_different_dut;

	stimulus_gen stim_inst (
		.clk(clk),
		.tb_match(tb_match),
		.in(in)
	);

	RefModule ref_mod_inst (
		.in(in),
		.out_both(out_both_ref),
		.out_any(out_any_ref),
		.out_different(out_different_ref)
	);

	TopModule dut_inst (
		.in(in),
		.out_both(out_both_dut),
		.out_any(out_any_dut),
		.out_different(out_different_dut)
	);

	// Verification logic
	integer i;
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		// Check overall correctness first
		if ({out_both_ref, out_any_ref, out_different_ref} !== ({out_both_ref, out_any_ref, out_different_ref} ^ {out_both_dut, out_any_dut, out_different_dut} ^ {out_both_ref, out_any_ref, out_different_ref})) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		// Check per-output
		// out_both
		if ({out_both_ref, out_both_dut, out_both_ref} !== ({out_both_ref, out_both_dut, out_both_ref})) begin
			if (stats1.errors_out_both == 0) stats1.errortime_out_both = $time;
			stats1.errors_out_both++;
		end
		// out_any
		for (i=0; i<100; i++) begin
			if (i == 0) begin // since out_any[0] is forced to 0
				if (out_any_ref[i] !== (out_any_ref[i] ^ out_any_dut[i] ^ out_any_ref[i])) begin
					if (stats1.errors_out_any == 0) stats1.errortime_out_any = $time;
					stats1.errors_out_any++;
				end
			end else begin
				if (out_any_ref[i] !== (out_any_ref[i] ^ out_any_dut[i] ^ out_any_ref[i])) begin
					if (stats1.errors_out_any == 0) stats1.errortime_out_any = $time;
					stats1.errors_out_any++;
				end
			end
		end
		// out_different
		for (i=0; i<100; i++) begin
			if (i == 99) begin // wrap around
				if (out_different_ref[i] !== (out_different_ref[i] ^ out_different_dut[i] ^ out_different_ref[i])) begin
					if (stats1.errors_out_different == 0) stats1.errortime_out_different = $time;
					stats1.errors_out_different++;
				end
			end else begin
				if (out_different_ref[i] !== (out_different_ref[i] ^ out_different_dut[i] ^ out_different_ref[i])) begin
					if (stats1.errors_out_different == 0) stats1.errortime_out_different = $time;
					stats1.errors_out_different++;
				end
			end
		end
	end

	// Display results
	final begin
		if (stats1.errors) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			if (stats1.errors_out_both) $display("First out_both mismatch at time: %0d", stats1.errortime_out_both);
			if (stats1.errors_out_any) $display("First out_any mismatch at time: %0d", stats1.errortime_out_any);
			if (stats1.errors_out_different) $display("First out_different mismatch at time: %0d", stats1.errortime_out_different);
		end else begin
			$display("SIMULATION PASSED");
		end
		$display("Total errors: %0d in %0d clocks", stats1.errors, stats1.clocks);
	end
endmodule

module stimulus_gen (input clk, input tb_match, output logic [99:0] in);
	initial begin
		randomize in with $random;
		repeat(100) begin
			@(negedge clk);
			randomize in with $random;
			@(posedge clk);
			randomize in with $random;
		end
		#1 $finish;
	end
endmodule

// Assume RefModule is correctly implemented elsewhere
module RefModule (input [99:0] in, output [99:0] out_both, output [99:0] out_any, output [99:0] out_different);
	assign out_both[99] = 1'b0;
	generate
		genvar i;
		for (i=0; i<99; i=i+1) begin : gen_out_both
			assign out_both[i] = in[i] & in[i+1];
		end
	endgenerate
	assign out_any[0] = 1'b0;
	generate
		for (i=1; i<100; i=i+1) begin : gen_out_any
			assign out_any[i] = in[i] | in[i-1];
		end
	endgenerate
	assign out_different[99] = in[99] ^ in[0];
	generate
		for (i=0; i<99; i=i+1) begin : gen_out_different
			assign out_different[i] = in[i] ^ in[i+1];
		end
	endgenerate
endmodule