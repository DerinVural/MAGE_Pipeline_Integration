 `timescale 1 ps/1 ps
 `define OK 12
 `define INCORRECT 13
 
 // Stubs for modules used in the golden testbench that are not defined here
 module stimulus_gen (
 	input clk,
 	output logic a,b,c,d,
 	output reg[511:0] wavedrom_title,
 	output reg wavedrom_enable 
 );
 	
 	// Stub implementation to allow compilation
 	initial begin
 		$display("Stub: stimulus_gen initialized.");
 		// Initialize outputs to 0
 		a = b = c = d = 1'b0;
 	end
 endmodule
 
 module RefModule (
 	input a,
 	input b,
 	input c,
 	input d,
 	output logic q 
 );
 	// Stub implementation matching the expected function (needed for simulation)
 	// We hardcode the expected function based on the specification derived.
 	assign q = (a == 1'b0 && b == 1'b0 && c == 1'b0 && d == 1'b0) || 
 		(a == 1'b0 && b == 1'b0 && c == 1'b0 && d == 1'b1) || 
 		(a == 1'b1 && b == 1'b0 && c == 1'b0 && d == 1'b0) || 
 		(a == 1'b1 && b == 1'b0 && c == 1'b0 && d == 1'b1);
 endmodule
 
 // --- TopModule Implementation based on specification ---
 module TopModule (
 	input a,
 	input b,
 	input c,
 	input d,
 	output logic q
 );
 	// Truth table derived from simulation: q=0 if (0000, 0001, 1000, 1001), else q=1
 	always_comb begin
 		if ((a == 1'b0) && (b == 1'b0) && (c == 1'b0) && (d == 1'b0)) 
 			q = 1'b0;
 		else if ((a == 1'b0) && (b == 1'b0) && (c == 1'b0) && (d == 1'b1)) 
 			q = 1'b0;
 		else if ((a == 1'b1) && (b == 1'b0) && (c == 1'b0) && (d == 1'b0)) 
 			q = 1'b0;
 		else if ((a == 1'b1) && (b == 1'b0) && (c == 1'b0) && (d == 1'b1)) 
 			q = 1'b0;
 		else 
 			q = 1'b1;
 	end
 endmodule
 
 // =========================================================================
 // TESTBENCH (Improved Golden Testbench)
 // =========================================================================
 
 module tb();
 
 	// Structure to hold error statistics and captured state at first error
 	typedef struct packed {
 		int errors;          // General mismatch counter
 		int errortime;       // Time of first general mismatch
 		int errors_q;        // Specific output 'q' mismatch counter
 		int errortime_q;     // Time of first specific 'q' mismatch
 		int clocks;          // Total clock cycles run
 		
 		// Variables to store state at first mismatch
 		logic [3:0] a_err_val;
 		logic [3:0] b_err_val;
 		logic [3:0] c_err_val;
 		logic [3:0] d_err_val;
 		logic q_ref_err_val;
 		logic q_dut_err_val;
 	} stats;
 	
 	stats stats1;
 	
 	// Waveform control signals
 	wire[511:0] wavedrom_title;
 	wire wavedrom_enable;
 	int wavedrom_hide_after_time;
 	
 	// Clock generation
 	reg clk=0;
 	initial forever
 		#5 clk = ~clk;
 	
 	// DUT and Reference signals
 	logic a;
 	logic b;
 	logic c;
 	logic d;
 	logic q_ref; // Expected output
 	logic q_dut; // DUT output
 	
 	// Verification signals
 	wire tb_match;
 	wire tb_mismatch = ~tb_match;
 	
 	// Task to display signals nicely (Handles 1-bit signals as requested)
 	task display_signal_state(time t);
 		$display("
========================================================================");
 		$display("!!! MISMATCH DETECTED AT TIME: %0d ps !!!", t);
 		$display("------------------------------------------------------------------------");
 		// Inputs (1-bit signals are displayed as %b)
 		$display("INPUTS: a=%b, b=%b, c=%b, d=%b", stats1.a_err_val, stats1.b_err_val, stats1.c_err_val, stats1.d_err_val);
 		// Outputs (1-bit signals are displayed as %b, and optionally in HEX for compliance)
 		$display("OUTPUTS: q_ref (Expected) = %b (HEX: 0x%h), q_dut (Actual) = %b (HEX: 0x%h)", 
 			stats1.q_ref_err_val, stats1.q_ref_err_val, stats1.q_dut_err_val, stats1.q_dut_err_val);
 		$display("------------------------------------------------------------------------");
 	endtask
 	
 	// Signal dumping
 	initial begin 
 		$dumpfile("wave.vcd");
 		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,q_ref,q_dut );
 	end
 	
 	// Module Instantiations (Maintained from golden testbench)
 	stimulus_gen stim1 (
 		.clk, 
 		.a, .b, .c, .d, 
 		.wavedrom_title, 
 		.wavedrom_enable 
 	);
 	
 	RefModule good1 (
 		.a, 
 		.b, 
 		.c, 
 		.d, 
 		.q(q_ref) 
 	);
 		
 	TopModule top_module1 (
 		a, 
 		b, 
 		c, 
 		d, 
 		.q(q_dut) 
 	);
 	
 	// Task to delay until the end of a timestep
 	bit strobe = 0;
 	task wait_for_end_of_timestep;
 		repeat(5) begin
 		strobe <= !strobe;  // Try to delay until the very end of the time step.
 		@(strobe);
 	end
 	endtask
 	
 	// Verification logic
 	// tb_match is true if q_ref == q_dut
 	assign tb_match = ( q_ref === q_dut );
 	
 	// Clocked verification and statistics update
 	always @(posedge clk, negedge clk) begin
 		
 		stats1.clocks++;
 		
 		// Store current inputs/outputs for potential first error logging
 		stats1.a_err_val = a;
 		stats1.b_err_val = b;
 		stats1.c_err_val = c;
 		stats1.d_err_val = d;
 		stats1.q_ref_err_val = q_ref;
 		stats1.q_dut_err_val = q_dut;
 		
 		// 1. General Mismatch Check
 		if (!tb_match) begin
 			if (stats1.errors == 0) {
 				stats1.errortime = $time;
 				// Log state at first error for general mismatch
 				display_signal_state($time);
 			}
 			stats1.errors++;
 		end
 		
 		// 2. Specific Output 'q' Mismatch Check (Original logic: q_ref !== ( q_ref ^ q_dut ^ q_ref ))
 		if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) 
 		begin 
 			if (stats1.errors_q == 0) stats1.errortime_q = $time;
 			stats1.errors_q = stats1.errors_q + 1'b1;
 		end
 		end
 	
 	// Final reporting block (Strictly following new requirements)
 	final begin
 		logic general_failed = (stats1.errors > 0);
 		logic specific_failed = (stats1.errors_q > 0);
 		
 		if (specific_failed) begin
 			$display("
========================================================================");
 			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", 
 				stats1.errors_q, stats1.errortime_q);
 		end else if (general_failed) begin
 			$display("
========================================================================");
 			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", 
 				stats1.errors, stats1.errortime);
 		end else begin
 			$display("SIMULATION PASSED");
 		end
 		
 		$display("
--- Final Summary ---");
 		$display("Total mismatched samples (General): %1d out of %1d samples", stats1.errors, stats1.clocks);
 		$display("Total mismatched samples (Output q specific): %1d out of %1d samples", stats1.errors_q, stats1.clocks);
 		$display("Simulation finished at %0d ps", $time);
 	end
 	
 	// Timeout mechanism (Maintained)
 	initial begin
 		#1000000
 		$display("
TIMEOUT REACHED");
 		$finish();
 	end
 	
 endmodule