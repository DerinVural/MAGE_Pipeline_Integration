`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen(
	input clk,
	output logic load,
	output logic [9:0] data,
	input tb_match,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable,
	output int wavedrom_hide_after_time
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
endtask
	
	task wavedrom_stop;
		h#1;
	endtask
	
	initial begin
		load <= 1'b0;
		wavedrom_start("Count 3, then 10 cycles");
		@(posedge clk) {data, load} <= {10'd3, 1'b1};
		@(posedge clk) {data, load} <= {10'hx, 1'b0};
		@(posedge clk) load <= 0;
		@(posedge clk) load <= 0;
		@(posedge clk) load <= 0;
		@(posedge clk) {data, load} <= {10'd10, 1'b1};
		@(posedge clk) {data, load} <= {10'hx, 1'b0};
		repeat(12) @(posedge clk);
		wavedrom_stop();

		@(posedge clk) {load, data} <= {1'b1, 10'h10};
		@(posedge clk) {load, data} <= {1'b0, 10'h10};
		@(posedge clk) {load, data} <= {1'b1, 10'h0};   // Load 0
		@(posedge clk) {load, data} <= {1'b1, 10'h3ff}; // Load 1023
		@(posedge clk) {load, data} <= {1'b0, 10'h0};
		repeat(1040) @(posedge clk);

		repeat(2500) @(posedge clk) begin
		load <= !(
			$urandom & 10'hf);
		data <= $urandom_range(0,32);
		end

		h#1 $finish;
	end

endmodule
module tb();

	// Define statistics structure
	typedef struct packed {
		int errors;
		int errortime;
		int errors_tc;
		int errortime_tc;
		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic load;
	logic [9:0] data;
	logic tc_ref;
	logic tc_dut;

	initial begin 
		$dumpfile("wave.vcd");
		// Dump all relevant signals for debugging
		$dumpvars(1, stimulus_gen.stim1, clk, load, data, tc_ref, tc_dut, tb_match, wavedrom_title);
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.load, 
		.data, 
		.tb_match, 
		wavedrom_title, 
		wavedrom_enable, 
		wavedrom_hide_after_time
);
	RefModule good1 (
		.clk, 
		.load, 
		.data, 
		.tc(tc_ref) );
	
	TopModule top_module1 (
		.clk,
		.load,
		.data,
		.tc(tc_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
	// Helper function to display signals in HEX and BIN if width <= 64	
	task display_signals;
		input string label;
		input logic [511:0] signal;
		input string type;
		
		begin
			$write("\n--- Signal Dump: %s at time %0t ---\n", label, $time);
			// Check width constraint for BIN display
			if (signal.size() <= 64) begin
				$write("| %s | %h | %b |
", type, signal, signal);
				end else begin
				$write("| %s | %h |
", type, signal);
				end
		end
		endtask
	
	// Overload for single bits
	task display_signals_1bit;
		input string label;
		input logic signal;
		
		begin
			$write("\n--- Signal Dump: %s at time %0t ---\n", label, $time);
			$write("| %s | %b |
", label, signal);
		endtask
		endtask
	
	// Function to handle display logic
	function void display_signal_formatted(input string name, input logic signal, input logic [9:0] data_sig, input logic tc_sig, input logic [511:0] wavedrom_sig);
		begin
			display_signals_1bit(name + "_load", signal);
			display_signals_1bit(name + "_tc_ref", tc_sig);
			display_signals_1bit(name + "_tc_dut", tc_sig);
			display_signals_1bit(name + "_tb_match", signal);
			display_signals_1bit(name + "_tb_mismatch", signal);
			display_signals_1bit(name + "_clk", signal);
			display_signals_1bit(name + "_data", data_sig);
			display_signals_1bit(name + "_wavedrom_title", wavedrom_sig);
		endfunction

	// Initialize stats
	initial begin
		stats1 = '{errors: 0, errortime: 0, errors_tc: 0, errortime_tc: 0, clocks: 0};
		// Initialize mismatch tracking variables
		logic [9:0] first_mismatch_data_ref = 0;
		logic [9:0] first_mismatch_data_dut = 0;
		logic first_mismatch_tc_ref = 0;
		logic first_mismatch_tc_dut = 0;
	end

	// Main clock/verification loop
	always @(posedge clk) begin
		stats1.clocks++;
		
		// Check main match (tb_match logic)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			
			// Log first mismatch details
			if (stats1.errors == 1) begin
				$display("\n========================================================================\n");
				$display("!!! FIRST MISMATCH DETECTED (tb_match) !!!");
				$display("Time: %0t ps", $time);
				$display("------------------------------------------------------------------------");
				$display("--- Inputs ---");
				display_signal_formatted("INPUT", load, data, tc_ref, wavedrom_title);
				$write("| load | %b | data | %h | %b |\n", load, data, tb_mismatch);
				$display("--- Outputs (DUT/REF) ---");
				display_signal_formatted("OUTPUT", 0, 0, tc_ref, wavedrom_title); // Using dummy args for display context
				display_signals_1bit("OUTPUT_tc_ref", tc_ref);
				display_signals_1bit("OUTPUT_tc_dut", tc_dut);
				$display("========================================================================\n");
			end
			// Store data for subsequent error logging if needed
			if (stats1.errors == 1) begin
				first_mismatch_data_ref = data;
			first_mismatch_data_dut = data;
			first_mismatch_tc_ref = tc_ref;
			first_mismatch_tc_dut = tc_dut;
			end
		end

		// Check specific TC mismatch
		if (tc_ref !== tc_dut) begin
			if (stats1.errors_tc == 0) stats1.errortime_tc = $time;
			sstats1.errors_tc++;
		end
		
		// Detailed logging for TC mismatch (if it is the first one)
		if (stats1.errors_tc == 1) begin
			$display("\n========================================================================\n");
			$display("!!! FIRST TC MISMATCH DETECTED !!!");
			$display("Time: %0t ps", $time);
			$display("------------------------------------------------------------------------");
			$display("--- Inputs ---");
			display_signal_formatted("INPUT", load, data, tc_ref, wavedrom_title);
			$write("| load | %b | data | %h | %b |\n", load, data, tb_mismatch);
			$display("--- Outputs (DUT/REF) ---");
			display_signals_1bit("OUTPUT_tc_ref", tc_ref);
			display_signals_1bit("OUTPUT_tc_dut", tc_dut);
			$display("========================================================================\n");
		end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final Reporting
	initial begin
		// Wait for simulation to settle before final report
		@(negedge clk);
		#1;
		
		int total_mismatches = stats1.errors + stats1.errors_tc;
		int first_error_time = 0;
		
		// Determine the absolute first error time
		if (stats1.errors > 0 && (stats1.errors_tc == 0 || stats1.errortime < stats1.errortime_tc)) begin
			first_error_time = stats1.errortime;
		end else if (stats1.errors_tc > 0) begin
			first_error_time = stats1.errortime_tc;
		end
		
		if (total_mismatches == 0) begin
			$display("\n======================================================================\n");
			$display("SIMULATION PASSED");
			$display("========================================================================\n");
		end else begin
			$display("\n======================================================================\n");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_error_time);
			$display("========================================================================\n");
		end
		$finish();
	endmodule