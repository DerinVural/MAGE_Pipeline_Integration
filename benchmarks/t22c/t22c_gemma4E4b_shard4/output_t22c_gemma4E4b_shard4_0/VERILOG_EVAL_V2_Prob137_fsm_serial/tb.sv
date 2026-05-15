`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic in,
	output logic reset
);
	
	initial begin
		reset <= 1;
		in <= 1;
		@(posedge clk);
		reset <= 0;
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(10) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(10) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		
		
		repeat(800) @(posedge clk, negedge clk) begin
		in <= $random;
		reset <= !($random & 31);
		end
		
		#1 $finish;
	end
	
endmodule

module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_done;
		int errortime_done;
		int clocks;
	} stats;
	
stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic in;
	logic reset;
	logic done_ref;
	logic done_dut;

	
initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,done_ref,done_dut );
	end

	
wire tb_match;	// Verification
wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		in, 
		.reset );
		
		RefModule good1 (
			.clk,
			in,
			.reset,
			done(done_ref) );
		
		TopModule top_module1 (
			.clk,
		in,
			.reset,
			done(done_dut) );

	
	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
	// --- Custom Mismatch Display Task --- 
	task report_mismatch;
		input int mismatch_count;
		input time_t mismatch_time;
		input logic expected_done;
		input logic actual_done;
		
		// Helper to display logic value in BIN and HEX if width <= 64
		task display_logic;
			input logic value;
			input string label;
			begin
				$display("  %s: %b (Hex: %h)", label, value, value);
			end
		endtask
		
		begin
			$display("\n===================================================================");
			$display("!!! FIRST MISMATCH DETECTED !!!");
			$display("Time: %0d ps", mismatch_time);
			$display("Error Count: %0d", mismatch_count);
			$display("--------------------------------------------------------------------");
			$display("Input Signals:");
			// Inputs are 1-bit signals, so BIN/HEX is straightforward
			$display("  clk: %b", clk);
			$display("  reset: %b", reset);
			$display("  in: %b", in);
			$display("Output Signals:");
			display_logic(actual_done, "done_dut");
			$display("Expected Output Signal:");
			display_logic(expected_done, "done_ref");
			$display("===================================================================\n");
		endtask
	
	
final begin
		if (stats1.errors_done) $display("Hint: Output 'done' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_done, stats1.errortime_done);
		else $display("Hint: Output 'done' has no mismatches.");
		
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		
		if (stats1.errors > 0) begin
			s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
		end
		else begin
			$display("SIMULATION PASSED");
		end
	end
	
	// Verification: If done_ref == done_dut, the XOR combination evaluates to 0.
// (done_ref === (done_ref ^ done_dut ^ done_ref)) simplifies to (done_ref === done_dut).
assign tb_match = (done_ref === done_dut);
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Check for general mismatch
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			// Report detailed mismatch upon first occurrence
			if (stats1.errors == 1) report_mismatch(1, $time, done_ref, done_dut);
		end
		
		// Check for specific error condition related to done_ref vs done_dut structure in golden TB
		if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
		begin 
			if (stats1.errors_done == 0) stats1.errortime_done = $time;
			sstats1.errors_done = stats1.errors_done+1'b1; 
		end
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT REACHED.");
		$finish();
	end

endmodule