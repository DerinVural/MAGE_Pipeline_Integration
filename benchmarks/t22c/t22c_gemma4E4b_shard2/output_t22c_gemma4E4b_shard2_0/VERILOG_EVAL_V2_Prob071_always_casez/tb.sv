`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] in, 
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
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
		@(negedge clk) wavedrom_start("Priority encoder");
		@(posedge clk) in <= 8'h1;
		repeat(8) @(posedge clk) in <= in << 1;
		in <= 8'h10;
		repeat(8) @(posedge clk) in <= in + 1;
		@(negedge clk) wavedrom_stop();

		repeat(50) @(posedge clk, negedge clk) begin
		in <= $urandom;
		end
		repeat(260) @(posedge clk, negedge clk) begin
		in <= in + 1;
		end
		$finish;
	end
	endmodule

module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_pos;
		int errortime_pos;
		int clocks;
		logic [7:0] in_at_first_error;
		logic [2:0] pos_dut_at_first_error;
		logic [2:0] pos_ref_at_first_error;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic [7:0] in;
	logic [2:0] pos_ref;
	logic [2:0] pos_dut;

	// Variables to hold signals at first error
	logic [7:0] in_snap;
	logic [2:0] pos_dut_snap;
	logic [2:0] pos_ref_snap;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen.stim1.clk, tb_mismatch, in, pos_ref, pos_dut );
	end

	
	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		in, 
		wavedrom_title, 
		wavedrom_enable
	);
	RefModule good1 (
		in, 
		.pos(pos_ref) );
	
	TopModule top_module1 (
		in, 
		.pos(pos_dut) );
	
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	endtask
	
	
	// Helper task for detailed error display
	task display_error_details;
		input integer time_val;
		input logic [7:0] in_val;
		input logic [2:0] pos_dut_val;
		input logic [2:0] pos_ref_val;
		
		$display("\n----------------------------------------------------------------------");
		$display("!!! FIRST MISMATCH DETECTED AT TIME: %0d ps !!!", time_val);
		$display("----------------------------------------------------------------------");
		$display("Input Signal (in):");
		$display("  HEX: %h", in_val);
		$display("  BIN: %b", in_val);
		$display("Expected Output (pos_ref):");
		$display("  HEX: %h", pos_ref_val);
		$display("  BIN: %b", pos_ref_val);
		$display("Actual Output (pos_dut):");
		$display("  HEX: %h", pos_dut_val);
		$display("  BIN: %b", pos_dut_val);
		$display("======================================================================");
	endtask
	
	
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			// Display detailed info for the first mismatch
		display_error_details(stats1.errortime, in_snap, pos_dut_snap, pos_ref_snap);
		end
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { pos_ref } === ( { pos_ref } ^ { pos_dut } ^ { pos_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// --- General Mismatch Tracking ---
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
		end
		// Snap signals only on the *first* mismatch
		if (stats1.errors == 1) begin
			in_snap <= in;
			pos_dut_snap <= pos_dut;
			pos_ref_snap <= pos_ref;
		end
		
		// --- POS Specific Mismatch Tracking ---
		if (pos_ref !== ( pos_ref ^ pos_dut ^ pos_ref ))
		begin 
			if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
			sstats1.errors_pos = stats1.errors_pos + 1'b1;
		end
		// Snap signals only on the *first* pos mismatch
		if (stats1.errors_pos == 1) begin
			in_snap <= in;
			pos_dut_snap <= pos_dut;
			pos_ref_snap <= pos_ref;
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("\n--- TIMEOUT REACHED ---");
		f$finish();
	end

endmodule
