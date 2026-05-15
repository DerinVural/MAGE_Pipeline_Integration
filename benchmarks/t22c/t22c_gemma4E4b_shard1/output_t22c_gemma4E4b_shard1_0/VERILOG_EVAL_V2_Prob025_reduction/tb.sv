`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generator (Kept from original)
module stimulus_gen (
	input clk,
	output logic [7:0] in
);
	initial begin
		repeat(100) @(posedge clk, negedge clk)
		in <= $random;
	end
	endmodule

// Helper task for displaying signals
task display_signal(input string name, input logic value, input int width);
	$display("    [%s] Value: %h (Binary: %b)", name, value, value);
endtask

task display_signal_array(input string name, input logic [7:0] value);
	// Width is 8 bits, which is <= 64, so we display binary
	$display("    [%s] Value: %h (Binary: %b)", name, value, value);
endtask

module tb();
	// Stats Structure
	typedef struct packed {
		int errors;
		int errortime;
		int errors_parity;
		int errortime_parity;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Waveform Control (Kept from original)
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	// Clock Generation	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	// DUT Signals
	logic [7:0] in;
	logic parity_ref;
	logic parity_dut;

	// Testbench Match & Mismatch
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Variables to capture first mismatch state
	logic [7:0] captured_in;
	logic captured_parity_dut;
	logic captured_parity_ref;
	int first_mismatch_time = -1;
	
	initial begin 
		$dumpfile("wave.vcd");
		// Matching the original dumpvars structure
		$dumpvars(1, stim1.clk, tb_mismatch, in, parity_ref, parity_dut );
	end

	// Instantiate Stimulus Generator
	stimulus_gen stim1 (
		.clk, 
		in
	);
	
	// Instantiate Reference Module (Assuming RefModule exists)
	// NOTE: RefModule definition is required for simulation but is assumed present.
	RefModule good1 (
		.in, 
		.parity(parity_ref) );
	
	// Instantiate DUT
	TopModule top_module1 (
		in, 
		.parity(parity_dut) );

	// Timing Task (Kept from original)
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask

	// Task placeholder for structural completeness, matching original
task 

	// === Main Simulation Control and Monitoring ===
	initial begin
		// Wait for initial setup phase to complete before starting detailed logging
		@(posedge clk);
		$display("--- Starting Simulation ---");
	end

	// Main Verification Logic
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { parity_ref } === ( { parity_ref } ^ { parity_dut } ^ { parity_ref } ) );

	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// --- 1. Check tb_match Mismatch ---
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				first_mismatch_time = $time;
				captured_in = in;
				captured_parity_dut = parity_dut;
				captured_parity_ref = parity_ref;
			end
			sstats1.errors++;
		end
		
		// --- 2. Check Parity Specific Mismatch ---
		if (parity_ref !== ( parity_ref ^ parity_dut ^ parity_ref ))
		begin 
			if (stats1.errors_parity == 0) begin
				stats1.errortime_parity = $time;
				// If this is the first overall error, capture it
			if (first_mismatch_time == -1) begin
					first_mismatch_time = $time;
					captured_in = in;
					captured_parity_dut = parity_dut;
					captured_parity_ref = parity_ref;
				end
			end
			sstats1.errors_parity = stats1.errors_parity+1'b1; 
		end
	end

	// Timeout
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final Reporting Block
	final begin
		$display("\n====================================================\n");
		if (stats1.errors > 0 || stats1.errors_parity > 0) begin
			int total_mismatches = stats1.errors + stats1.errors_parity;
			// Use captured_in state if available, otherwise use current time as fallback for first error time
			int first_error_time = (first_mismatch_time != -1) ? first_mismatch_time : 0;
			
			// Required Failure Message Format
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_error_time);
			$display("\n--- Details of First Mismatch at Time %0d ps ---", first_error_time);
			$display("Input Signal (in): ");
			display_signal_array("in", captured_in);
			$display("DUT Output (parity_dut): ");
			display_signal("parity_dut", captured_parity_dut, 1);
			$display("Expected Output (parity_ref): ");
			display_signal("parity_ref", captured_parity_ref, 1);
			$display("------------------------------------------------------");
		end else begin
			// Required Success Message Format
			$display("SIMULATION PASSED");
			end
		$display("Simulation finished at %0d ps", $time);
	end

endmodule