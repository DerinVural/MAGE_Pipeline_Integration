`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] in
);
	initial begin
		repeat(100) @(posedge clk, negedge clk)
		in <= $random;
	end
	$finish;
endmodule

// Mock module for RefModule (as its implementation is not provided, we must define a simple placeholder matching the interface used in the golden TB)
module RefModule (
	input logic [7:0] in,
	output logic [31:0] out
);
	// Placeholder implementation mirroring the required operation for golden comparison, assuming it performs sign extension
	assign out = { {8'b0}, in }; 
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

	logic [7:0] in;
	logic [31:0] out_ref;
	logic [31:0] out_dut;

	// Signals to capture the first mismatch state for detailed logging
	logic [7:0] captured_in;
	logic [31:0] captured_out_dut;
	logic [31:0] captured_out_ref;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end

	// Signals for verification
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.*,
		.in);
	RefModule good1 (
		.in,
		.out(out_ref) );
	
	TopModule top_module1 (
		in(in),
		.out(out_dut) );

	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task

	final begin
		if (stats1.errors_out) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_out, stats1.errortime_out);
			$display("--- FIRST MISMATCH DETAILS ---");
			$display("Time: %0d ps", stats1.errortime_out);
			// Displaying signals in HEX and BIN format if width <= 64
			$display("Input Signals (in): HEX=%h, BIN=%b", captured_in, captured_in);
			$display("DUT Output Signals (out): HEX=%h, BIN=%b", captured_out_dut, captured_out_dut);
			$display("Expected Output Signals (out_ref): HEX=%h, BIN=%b", captured_out_ref, captured_out_ref);
			
			$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
			
			// Ensure the required final failure format is met
			end
		end
		
		// Check for success
		if (stats1.errors == 0 && stats1.errors_out == 0) begin
			s$display("SIMULATION PASSED");
		end
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1;
			
			// Capture state at first output mismatch
		if (stats1.errors_out == 1) begin
				captured_in = in;
				out_dut = out_dut; // Redundant assignment, but kept for structure
				captured_out_dut = out_dut;
				captured_out_ref = out_ref;
			end
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule