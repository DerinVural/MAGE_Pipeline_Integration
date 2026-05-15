`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg in = 0
);
	
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
		in <= $random;
		end
		#1 $finish;
	end
	endmodule

module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic in_tb; // Input signal driven by stimulus_gen
	logic out_ref; // Expected output from RefModule
	logic out_dut; // Actual output from TopModule
	
	// Signals to capture state at first mismatch
	logic first_mismatch_inputs;
	logic first_mismatch_expected_out;
	logic first_mismatch_actual_out;
	
	initial begin 
		$dumpfile("wave.vcd");
		// Dump all relevant signals
		$dumpvars(1, tb, in_tb, out_ref, out_dut, first_mismatch_inputs, first_mismatch_expected_out, first_mismatch_actual_out);
	end
	
	
wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk, // Passing clk to stimulus_gen
		.* , // Maintain original port connection style
		in );
	RefModule good1 (
		.in, // Connects to stimulus_gen.in
		out(out_ref) );
	
TopModule top_module1 (
		.in(in_tb),
		out(out_dut) );
	
	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	endtask
	
	
// Initialize stats
initial begin
	stats1 = '{errors: 0, errortime: 0, errors_out: 0, errortime_out: 0, clocks: 0};
end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
// The core clock/verification process
always @(posedge clk, negedge clk) begin
	stats1.clocks++;
	
	// --- Mismatch Detection (Total Errors) ---
	if (!tb_match) begin
		if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Capture state at first error
			first_mismatch_inputs = in_tb;
			first_mismatch_expected_out = out_ref;
			first_mismatch_actual_out = out_dut;
			end
		stats1.errors++;
		end
	
	// Original specific check (Error counting for errors_out)
	if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
	begin 
		if (stats1.errors_out == 0) stats1.errortime_out = $time;
		sstats1.errors_out = stats1.errors_out+1'b1; 
	end
end
	
	
// Task execution (kept for structural integrity)
initial begin
	@(posedge clk);
	wait_for_end_of_timestep();
end
	
	// Final reporting block - IMPROVED
final begin
	if (stats1.errors > 0) begin
		$display("\n=====================================================");
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		$display("--- FIRST MISMATCH DETAILS ---");
		// 1. Display Input Signals
		$display("Input Signals (in): Value=%b (Hex: %h) at Time %0d", first_mismatch_inputs, first_mismatch_inputs, stats1.errortime);
		// 2. Display Expected Output Signals
		$display("Expected Output (out_ref): Value=%b (Hex: %h) at Time %0d", first_mismatch_expected_out, first_mismatch_expected_out, stats1.errortime);
		// 3. Display Actual Output Signals
		$display("Actual Output (out_dut): Value=%b (Hex: %h) at Time %0d", first_mismatch_actual_out, first_mismatch_actual_out, stats1.errortime);
		$display("=====================================================");
	end else begin
		$display("\n=====================================================");
		$display("SIMULATION PASSED");
		$display("=====================================================");
	end
	
		$display("Total mismatched samples (Verification Check): %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches (Specific Check): %1d in %1d samples", stats1.errors_out, stats1.clocks);
end
	
	// add timeout after 100K cycles
initial begin
	#1000000
	$display("\nTIMEOUT REACHED");
	$finish();
end

endmodule