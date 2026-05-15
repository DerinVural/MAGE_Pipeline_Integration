`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generator (Unchanged functionality)
module stimulus_gen (
	input clk,
	output logic[5:0] y,
	output logic w,
	input tb_match
);
	int errored1 = 0;
	int onehot_error = 0;
	int temp;
	
	initial begin
		// Test the one-hot cases first.
		repeat(200) @(posedge clk, negedge clk) begin
		y <= 1<< ($unsigned($random) % 6);
		w <= $random;
		if (!tb_match) onehot_error++;
		end
		
		// Random.
		errored1 = 0;
		repeat(400) @(posedge clk, negedge clk) begin
		do 
		temp = $random;
		while ( !{temp[5:4],temp[2:1]} == !{temp[3],temp[0]} );
		// Make y[3,0] and y[5,4,2,1] mutually exclusive, so we can accept Y3=(~y[3] & ~y[0]) &~w as a valid answer too.
		y <= temp;
		w <= $random;
		if (!tb_match)
			errored1++;
		end
		if (!onehot_error && errored1) 
		$display ("Hint: Your circuit passed when given only one-hot inputs, but not with semi-random inputs.");
		
		if (!onehot_error && errored1)
		$display("Hint: Are you doing something more complicated than deriving state transition equations by inspection?\n");
		
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_Y1;
		int errortime_Y1;
		int errors_Y3;
		int errortime_Y3;
		int clocks;
		// Variables to capture state at the first error
		logic [5:0] y_at_first_error;
		logic w_at_first_error;
		logic Y1_ref_at_first_error;
		logic Y1_dut_at_first_error;
		logic Y3_ref_at_first_error;
		logic Y3_dut_at_first_error;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [5:0] y;
	logic w;
	logic Y1_ref;
	logic Y1_dut;
	logic Y3_ref;
	logic Y3_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen.clk, tb_mismatch, y, w, Y1_ref, Y1_dut, Y3_ref, Y3_dut );
	end

	
wire tb_match;
wire tb_mismatch = ~tb_match;
	
	// Instantiate Stimulus Generator
	stimulus_gen stim1 (
		.clk, 
		.*, 
		y, 
		w);
	
	// Instantiate Reference Model
	RefModule good1 (
		.y, 
		w, 
		.Y1(Y1_ref), 
		.Y3(Y3_ref) );
		
	// Instantiate DUT
	TopModule top_module1 (
		y, 
		w, 
		.Y1(Y1_dut), 
		.Y3(Y3_dut) );

	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
// Helper task to display signals in HEX and BIN format
task display_signal;
		input logic [5:0] data;
		input string name;
		begin
			$display("%-20s: HEX = %h, BIN = %b", name, data, data);
		endtask
		endtask
	
	final begin
		// 1. Display Detailed Mismatch Information if any occurred
		if (stats1.errors > 0) begin
			$display("
====================================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- State at First Total Mismatch ---");
			// Display inputs y and w in required format
			$display("Inputs: y = %h (%b), w = %b", stats1.y_at_first_error, stats1.y_at_first_error, stats1.w_at_first_error);
			// Display outputs in required format
			$display("Outputs: DUT Y1 = %b, DUT Y3 = %b", stats1.Y1_dut_at_first_error, stats1.Y3_dut_at_first_error);
			$display("Expected: REF Y1 = %b, REF Y3 = %b", stats1.Y1_ref_at_first_error, stats1.Y3_ref_at_first_error);
			$display("====================================================\n");
		end else begin
			$display("SIMULATION PASSED");
		end
		
		// 2. Original individual error hints (kept for compatibility)
		if (stats1.errors_Y1 > 0) $display("Hint: Output 'Y1' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_Y1, stats1.errortime_Y1);
		if (stats1.errors_Y3 > 0) $display("Hint: Output 'Y3' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_Y3, stats1.errortime_Y3);
		
		$display("Total mismatched samples: %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Final Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

// Verification: tb_match calculation
// Simplified check: {Y1_ref, Y3_ref} === {Y1_dut, Y3_dut}
assign tb_match = ( { Y1_ref, Y3_ref } === { Y1_dut, Y3_dut } );

// Monitoring and Error Counting
always @(posedge clk, negedge clk) begin
	
	stats1.clocks++;
	
	// Check overall mismatch
	if (!tb_match) begin
		if (stats1.errors == 0) begin
		stats1.errortime = $time;
		// Capture state at first total mismatch
		s1.y_at_first_error = y;
		s1.w_at_first_error = w;
		s1.Y1_ref_at_first_error = Y1_ref;
		s1.Y1_dut_at_first_error = Y1_dut;
		s1.Y3_ref_at_first_error = Y3_ref;
		s1.Y3_dut_at_first_error = Y3_dut;
		end
		s1.errors++;
	end
	
	// Check Y1 mismatch
	if (Y1_ref !== Y1_dut) begin
		if (stats1.errors_Y1 == 0) stats1.errortime_Y1 = $time;
		s1.errors_Y1 = stats1.errors_Y1 + 1'b1;
		end
	
	// Check Y3 mismatch
	if (Y3_ref !== Y3_dut) begin
		if (stats1.errors_Y3 == 0) stats1.errortime_Y3 = $time;
		s1.errors_Y3 = stats1.errors_Y3 + 1'b1;
		end
	end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("\nTIMEOUT REACHED");
	$finish();
end

endmodule