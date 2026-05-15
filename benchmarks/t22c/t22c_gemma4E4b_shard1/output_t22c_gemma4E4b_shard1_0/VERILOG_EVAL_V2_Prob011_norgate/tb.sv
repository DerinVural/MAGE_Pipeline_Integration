`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


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
		wavedrom_start("NOR gate");
		repeat(10) @(posedge clk)
			{a,b} <= count++;
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{b,a} <= $random;
		
		h#1 $finish;
	end
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
		h#5 clk = ~clk;

	
	logic a;
	logic b;
	logic out_ref;
	logic out_dut;

	// State tracking for enhanced logging
	reg first_mismatch_detected = 0;
	reg first_mismatch_time_captured = 0;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, a, b, out_ref, out_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, clk,
		.a, a,
		.b, b,
		.wavedrom_title, wavedrom_title,
		.wavedrom_enable, wavedrom_enable 
	);
	RefModule good1 (
		.a, a,
		.b, b,
		.out(out_ref) );
	
	TopModule top_module1 (
		.a, a,
		.b, b,
		.out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
		endtask

	
	final begin
		if (stats1.errors_out > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_out, stats1.errortime_out);
			
			// Display state at first mismatch time (based on errors_out)
			$display("--- FIRST MISMATCH DETECTED AT TIME %0d ps (errors_out) ---", stats1.errortime_out);
			$display("Input a: %b, Input b: %b", a, b);
			// Displaying in HEX format as required for multi-bit, which covers 1-bit too
			$display("Expected Output (out_ref): %b (HEX: %h)", out_ref, out_ref);
			$display("DUT Output (out_dut): %b (HEX: %h)", out_dut, out_dut);
			$display("---------------------------------------");
		end
		else begin
			$display("SIMULATION PASSED");
		end
		
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				sstats1.errortime = $time;
				first_mismatch_detected = 1;
				// Capture state at the time of the first overall mismatch
				$display("*** FIRST OVERALL MISMATCH DETECTED *** Time: %0d ps", $time);
				$display("Inputs: a=%b, b=%b", a, b);
				$display("Expected Ref Output: %b (HEX: %h)", out_ref, out_ref);
				$display("DUT Output: %b (HEX: %h)", out_dut, out_dut);
				first_mismatch_time_captured = 1;
			end
			sstats1.errors++;
		end
		
		// Logic for errors_out (specific check)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) begin
				sstats1.errortime_out = $time;
				// Capture state at the time of the first errors_out mismatch
				$display("*** FIRST ERRORS_OUT MISMATCH DETECTED *** Time: %0d ps", $time);
				$display("Inputs: a=%b, Input b: %b", a, b);
				$display("Expected Ref Output: %b (HEX: %h)", out_ref, out_ref);
				$display("DUT Output: %b (HEX: %h)", out_dut, out_dut);
				sstats1.errors_out = 1;
			end
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule