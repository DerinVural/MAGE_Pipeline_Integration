`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generator (Kept from Golden Testbench)
module stimulus_gen (
	input clk,
	output logic [255:0] in,
	output logic [7:0] sel
);
	
	always @(posedge clk, negedge clk) begin
		for (int i=0;i<8; i++) 
			in[i*32+:32] <= $random;
		sel <= $random;
	end
	
	initial begin
		repeat(1000) @(negedge clk);
		$finish;
	end
	endmodule

// Reference Module (Stub, matches DUT interface)
module RefModule (
	input logic [255:0] in,
	input logic [7:0] sel,
	output logic out
);
	// MUX implementation: select in[sel]
	assign out = in[sel];
endmodule

// Top Module (DUT) - Implementation based on spec
module TopModule (
	input  logic [255:0] in,
	input  logic [7:0] sel,
	output logic out
);
	// MUX implementation: select in[sel]
	assign out = in[sel];
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
	
	// Signal dumping setup (Kept from Golden Testbench)
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic [255:0] in;
	logic [7:0] sel;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, tb);
	end

	// Verification signals
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Signal capturing for detailed error reporting
	logic [255:0] captured_in;
	logic [7:0] captured_sel;
	logic captured_out_ref;
	logic captured_out_dut;

	// Task to display signals in required format (HEX/BIN) - Used for first mismatch report
	task display_signal;
		input logic [255:0] in_val;
		input logic [7:0] sel_val;
		input logic out_ref_val;
		input logic out_dut_val;
		
		$display("--------------------------------------------------");
		$display("!!! MISMATCH DETECTED at time %0d ps !!!", $time);
		$display("--- Inputs ---");
		// Display IN (256b) - Always show HEX and BIN
		$display("IN (256b): HEX=%h, BIN=%b", in_val, in_val);
		// Display SEL (8b) - Width <= 64, so show HEX and BIN
		$display("SEL (8b): HEX=%h, BIN=%b", sel_val, sel_val);
		$display("--- Outputs ---");
		// Display REF OUT (1b) - Always show HEX and BIN
		$display("REF OUT (1b): HEX=%b, BIN=%b", out_ref_val, out_ref_val);
		// Display DUT OUT (1b) - Always show HEX and BIN
		$display("DUT OUT (1b): HEX=%b, BIN=%b", out_dut_val, out_dut_val);
		$display("==================================================");
	endtask

	// Task to handle detailed mismatch logging
	task log_mismatch;
		input logic [255:0] in_val;
		input logic [7:0] sel_val;
		input logic out_ref_val;
		input logic out_dut_val;
		
		// Update statistics
		stats1.errors++;
		if (stats1.errors == 1) stats1.errortime = $time;
		
		// Update output errors statistics
		if (stats1.errors_out == 0) stats1.errortime_out = $time;
		stats1.errors_out++;
		
		// Display detailed information (Rule 1 of improved testbench)
		display_signal(in_val, sel_val, out_ref_val, out_dut_val);
	endtask

	// Instantiate stimulus generator
	stimulus_gen stim1 (
		.clk, 
		in, 
		.sel);
	
	// Instantiate Reference Module
	RefModule good1 (
		in, 
		.sel, 
		.out(out_ref) );
	
	// Instantiate DUT
	TopModule top_module1 (
		in, 
		.sel, 
		.out(out_dut) );

	
	// Verification logic: Simple equality check since all are 1-bit results
	assign tb_match = (out_ref == out_dut);

	// Clocked process for counting errors and triggering logging
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		if (!tb_match) begin
			// Log the mismatch event using the current state of inputs/outputs
			log_mismatch(in, sel, out_ref, out_dut);
		end
		
		// Capture values only on the clock edge
		captured_in <= in;
		captured_sel <= sel;
		captured_out_ref <= out_ref;
		captured_out_dut <= out_dut;
	end

	
	// Timeout mechanism
	initial begin
		#1000000
		$display("TIMEOUT REACHED AFTER 1,000,000 CYCLES.");
		end

	// Final reporting logic (Rule 4 requirement)
	initial begin
		// Wait until stimulus_gen finishes (which is after 1000 cycles)
		@(negedge clk);
		@(negedge clk); // Give time for the last clock edge to register
		
		if (stats1.errors == 0) begin
			$display("
========================================");
			$display("SIMULATION PASSED");
			$display("========================================");
		end else begin
			$display("
========================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("========================================");
		end
		$display("Simulation finished at %0d ps", $time);
	end

endmodule