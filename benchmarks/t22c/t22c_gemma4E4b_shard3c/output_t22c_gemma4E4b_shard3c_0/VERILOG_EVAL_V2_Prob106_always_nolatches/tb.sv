`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic [15:0] scancode, 
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
		@(negedge clk) wavedrom_start("Recognize arrow keys");
		@(posedge clk) scancode <= 16'h0;
		@(posedge clk) scancode <= 16'h1;
		@(posedge clk) scancode <= 16'he075;
		@(posedge clk) scancode <= 16'he06b;
		@(posedge clk) scancode <= 16'he06c;
		@(posedge clk) scancode <= 16'he072;
		@(posedge clk) scancode <= 16'he074;
		@(posedge clk) scancode <= 16'he076;
		@(posedge clk) scancode <= 16'hffff;
		@(negedge clk) wavedrom_stop();

		repeat(30000) @(posedge clk, negedge clk) begin
		scancode <= $urandom;
		end
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_left;
		int errortime_left;
		int errors_down;
		int errortime_down;
		int errors_right;
		int errortime_right;
		int errors_up;
		int errortime_up;
		int clocks;
		// Signals to capture state at first mismatch
		int first_mismatch_time;
		logic [15:0] input_scancode_at_mismatch;
		logic left_dut_at_mismatch;
		logic down_dut_at_mismatch;
		logic right_dut_at_mismatch;
		logic up_dut_at_mismatch;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [15:0] scancode;
	logic left_ref;
	logic left_dut;
	logic down_ref;
	logic down_dut;
	logic right_ref;
	logic right_dut;
	logic up_ref;
	logic up_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,scancode,left_ref,left_dut,down_ref,down_dut,right_ref,right_dut,up_ref,up_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		.scancode );
	RefModule good1 (
		.scancode,
		.left(left_ref),
		.down(down_ref),
		.right(right_ref),
		.up(up_ref) );
	
	TopModule top_module1 (
		.scancode,
		.left(left_dut),
		.down(down_dut),
		.right(right_dut),
		.up(up_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
	// Variables to track the *first* mismatch state for reporting
	reg first_mismatch_detected = 0;
	reg first_mismatch_left = 0;
	reg first_mismatch_down = 0;
	reg first_mismatch_right = 0;
	reg first_mismatch_up = 0;
	
	
	// Main clock/logic block
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// Check overall mismatch
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Check specific output mismatches and capture first error state
		if (left_ref !== left_dut) begin
			if (stats1.errors_left == 0) begin
			sstats1.errortime_left = $time;
			sstats1.first_mismatch_time = $time;
			sstats1.input_scancode_at_mismatch = scancode;
			sstats1.left_dut_at_mismatch = left_dut;
			sstats1.down_dut_at_mismatch = down_dut;
			sstats1.right_dut_at_mismatch = right_dut;
			sstats1.up_dut_at_mismatch = up_dut;
			first_mismatch_left = 1;
			end
			sstats1.errors_left = stats1.errors_left+1'b1;
		end
		
		if (down_ref !== down_dut) begin
			if (stats1.errors_down == 0) begin
			sstats1.errortime_down = $time;
			sstats1.first_mismatch_time = $time;
			sstats1.input_scancode_at_mismatch = scancode;
			sstats1.left_dut_at_mismatch = left_dut;
			sstats1.down_dut_at_mismatch = down_dut;
			sstats1.right_dut_at_mismatch = right_dut;
			sstats1.up_dut_at_mismatch = up_dut;
			first_mismatch_down = 1;
			end
			sstats1.errors_down = stats1.errors_down+1'b1;
		end
		
		if (right_ref !== right_dut) begin
			if (stats1.errors_right == 0) begin
			sstats1.errortime_right = $time;
			sstats1.first_mismatch_time = $time;
			sstats1.input_scancode_at_mismatch = scancode;
			sstats1.left_dut_at_mismatch = left_dut;
			sstats1.down_dut_at_mismatch = down_dut;
			sstats1.right_dut_at_mismatch = right_dut;
			sstats1.up_dut_at_mismatch = up_dut;
			first_mismatch_right = 1;
			end
			sstats1.errors_right = stats1.errors_right+1'b1;
		end
		
		if (up_ref !== up_dut) begin
			if (stats1.errors_up == 0) begin
			sstats1.errortime_up = $time;
			sstats1.first_mismatch_time = $time;
			sstats1.input_scancode_at_mismatch = scancode;
			sstats1.left_dut_at_mismatch = left_dut;
			sstats1.down_dut_at_mismatch = down_dut;
			sstats1.right_dut_at_mismatch = right_dut;
			sstats1.up_dut_at_mismatch = up_dut;
			first_mismatch_up = 1;
			end
			sstats1.errors_up = stats1.errors_up+1'b1;
		end
		
	end

	
	// Verification check (must be preserved)
	assign tb_match = ( { left_ref, down_ref, right_ref, up_ref } === ( { left_ref, down_ref, right_ref, up_ref } ^ { left_dut, down_dut, right_dut, up_dut } ^ { left_ref, down_ref, right_ref, up_ref } ) );
	
	
	// add timeout after 100K cycles
	initial begin
		#1000000
		if (stats1.clocks < 1000000) begin
			$display("TIMEOUT: Simulation ended prematurely at %0d cycles.", stats1.clocks);
			// If timeout occurs before final block runs, we must manually check and report
			if (stats1.errors > 0) begin
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
				$display("--- Details of First Overall Mismatch (Time %0d) ---", stats1.errortime);
				$display("Input Scancode: HEX=%h, BIN=%b", stats1.input_scancode_at_mismatch, stats1.input_scancode_at_mismatch);
				$display("Expected Outputs: L=%b, D=%b, R=%b, U=%b", left_ref, down_ref, right_ref, up_ref);
				$display("Actual Outputs:   L=%b, D=%b, R=%b, U=%b", left_dut_at_mismatch, down_dut_at_mismatch, right_dut_at_mismatch, up_dut_at_mismatch);
			end
			$finish;
		end

	
	// Final reporting block - REVISED to meet new requirements
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
			$display("Total tested samples: %0d", stats1.clocks);
			end
		else begin
			// Requirement: SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME y
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			
			// Requirement: Display detailed info at the time of the FIRST overall mismatch (stats1.errortime)
			$display("--- Details of First Overall Mismatch (Time %0d) ---", stats1.errortime);
			
			// Requirement: Display input signals in HEX and BIN (16 bits <= 64)
			$display("Input Scancode: HEX=%h, BIN=%b", stats1.input_scancode_at_mismatch, stats1.input_scancode_at_mismatch);
			
			$display("Expected Outputs: L=%b, D=%b, R=%b, U=%b", left_ref, down_ref, right_ref, up_ref);
			$display("Actual Outputs:   L=%b, D=%b, R=%b, U=%b", left_dut_at_mismatch, down_dut_at_mismatch, right_dut_at_mismatch, up_dut_at_mismatch);
			end
	end

endmodule