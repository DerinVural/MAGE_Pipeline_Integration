`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assuming RefModule exists and matches the necessary interface for compilation
module RefModule (
    input logic clk,
    input logic reset,
    input logic w,
    output logic z
);
    // Dummy implementation for compilation completeness, matching the expected interface
    assign z = 1'b0;
endmodule

module stimulus_gen (
	input logic clk,
	output logic reset,
	output logic w
);
	initial begin
		repeat(200) @(posedge clk, negedge clk) begin
		w <= $random;
		reset <= ($random & 15) == 0;
		end
		h#1 $finish;
	endmodule

module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Variables kept from original testbench structure for compatibility
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic reset;
	logic w;
	logic z_ref;
	logic z_dut;

	initial begin 
		$dumpfile("wave.vcd");
		// Ensure all signals being dumped are declared in the scope
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,w,z_ref,z_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus generator
	stimulus_gen stim1 (
		.clk, 
		.* , // Following golden testbench structure
		.reset,
		w );
	
	// Instantiate Reference Model	// Follows golden testbench structure
	RefModule good1 (
		.clk,
		.reset,
		w,
		z(z_ref) );
	
	// Instantiate DUT	// Follows golden testbench structure
	TopModule top_module1 (
		.clk,
		.reset,
		w,
		z(z_dut) );
	
	
	// Task definition
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end	task
	
	// Task definition for detailed mismatch reporting
	task display_signals;
		$display("
=======================================================");
		$display("--- FIRST MISMATCH DETECTED ---");
		$display("Time: %0d ps", $time);
		$display("Input Signals:");
		// All signals are 1-bit, so binary and hex are the same representation
		$display("  clk: %b (0x%h)", logic_clk_mismatch, logic_clk_mismatch);
		$display("  reset: %b (0x%h)", logic_reset_mismatch, logic_reset_mismatch);
		$display("  w: %b (0x%h)", logic_w_mismatch, logic_w_mismatch);
		$display("Output Signals:");
		$display("  DUT Output (z_dut): %b (0x%h)", logic_z_dut_mismatch, logic_z_dut_mismatch);
		$display("  Expected Output (z_ref): %b (0x%h)", logic_z_ref_mismatch, logic_z_ref_mismatch);
		$display("=======================================================");
	endtask
	
	
	// Capture state variables for the first mismatch display
	reg logic first_mismatch_captured = 0;
	logic logic_clk_mismatch = 0;
	logic logic_reset_mismatch = 0;
	logic logic_w_mismatch = 0;
	logic logic_z_dut_mismatch = 0;
	logic logic_z_ref_mismatch = 0;
	
	// Monitor Logic: Replaces the old final block logic for dynamic reporting
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// Check for general mismatch (tb_match)
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Capture signals at the exact time of first mismatch
			logic_clk_mismatch = clk;
			logic_reset_mismatch = reset;
			logic_w_mismatch = w;
			logic_z_dut_mismatch = z_dut;
			logic_z_ref_mismatch = z_ref;
			first_mismatch_captured = 1;
			display_signals();
			end
			sstats1.errors++;
		end
		
		// Original error counting logic (maintaining functionality)
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin 
			if (stats1.errors_z == 0) stats1.errortime_z = $time;
			sstats1.errors_z = stats1.errors_z + 1'b1; 
		end
		end
	
	// Add timeout after 100K cycles
	initial begin
		#1000000
		$display("
=======================================================");
		if (stats1.errors == 0)
			s$display("SIMULATION PASSED");
		else
			s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		$display("=======================================================");
		$finish();
	end

endmodule