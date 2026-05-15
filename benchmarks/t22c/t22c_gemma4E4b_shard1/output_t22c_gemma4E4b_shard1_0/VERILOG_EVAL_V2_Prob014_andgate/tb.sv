`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Assuming stimulus_gen, RefModule, and TopModule exist for compilation context.

module stimulus_gen (
	input clk,
	output reg a, b,
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
		int count; count = 0;
		{a,b} <= 1'b0;
		wavedrom_start("AND gate");
		repeat(10) @(posedge clk)
			{a,b} <= count++;
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{b,a} <= $random;
		
		#1 $finish;
	end
	endmodule

module RefModule (
	input a,
	input b,
	output out
);
	assign out = a & b;
	endmodule

// The module under test
module TopModule (
	input a,
	input b,
	output out
);
	// Implementation of 2-input AND gate
	assign out = a & b;
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
	
	// Variables to capture state at the *first* mismatch
	reg captured_a = 0;
	reg captured_b = 0;
	reg captured_out_ref = 0;
	reg captured_out_dut = 0;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic a;
	logic b;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		// Dump relevant signals for waveform viewing
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,out_ref,out_dut );
	end

	
	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		.a,
		.b );
	RefModule good1 (
		a,
		b,
		out(out_ref) );
	
	TopModule top_module1 (
		a,
		b,
		out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task

	final begin
		if (stats1.errors_out) begin
			// Specific Output Mismatch Report
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_out, stats1.errortime_out);
			$display("--- First Output Mismatch Details (Time %0d) ---", stats1.errortime_out);
			// Display inputs and outputs for the first specific mismatch
			$display("Inputs: a=%b (HEX: %h), b=%b (HEX: %h)", captured_a, captured_a, captured_b, captured_b);
			$display("Outputs: DUT=%b (HEX: %h), REF=%b (HEX: %h)", captured_out_dut, captured_out_dut, captured_out_ref, captured_out_ref);
			
			// Reset captured values
			captured_a = 0; captured_b = 0; captured_out_ref = 0; captured_out_dut = 0;
			
		end else begin
			$display("SIMULATION PASSED");
		end
	
		if (stats1.errors) begin
			// General Mismatch Report
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
			$display("--- First General Mismatch Details (Time %0d) ---", stats1.errortime);
			// Display inputs and outputs for the first general mismatch
			$display("Inputs: a=%b (HEX: %h), b=%b (HEX: %h)", captured_a, captured_a, captured_b, captured_b);
			$display("Outputs: DUT=%b (HEX: %h), REF=%b (HEX: %h)", captured_out_dut, captured_out_dut, captured_out_ref, captured_out_ref);
			
			// Reset captured values
			captured_a = 0; captured_b = 0; captured_out_ref = 0; captured_out_dut = 0;
		end
	
		$display("\nTotal mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// General Mismatch Tracking
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				sstats1.errortime = $time; // Corrected reference
				captured_a = a; 
				captured_b = b;
				captured_out_ref = out_ref;
				captured_out_dut = out_dut;
			end
			sstats1.errors++; // Corrected reference
		end
		
		// Specific Output Mismatch Tracking
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) begin
				sstats1.errortime_out = $time; // Corrected reference
				captured_a = a; 
				captured_b = b;
				captured_out_ref = out_ref;
				captured_out_dut = out_dut;
			end
			sstats1.errors_out = stats1.errors_out+1'b1; // Corrected reference
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT: Simulation exceeded 1,000,000 cycles.");
		$finish();
	end

endmodule