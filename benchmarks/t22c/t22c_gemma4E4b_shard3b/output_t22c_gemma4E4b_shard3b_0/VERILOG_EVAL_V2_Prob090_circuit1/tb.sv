`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic a,b,
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
		{a,b} <= 0;
		@(negedge clk) wavedrom_start("Unknown circuit");
		@(posedge clk) {a,b} <= 0;
		repeat(8) @(posedge clk) {a,b} <= {a,b} + 1;
		@(negedge clk) wavedrom_stop();
		
		repeat(100) @(posedge clk, negedge clk)
			{a,b} <= $urandom;
		$finish;
	end

endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
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
	logic q_ref;
	logic q_dut;

	// Signals to capture the state at the first mismatch
	logic first_mismatch_captured = 0;
	logic captured_a, captured_b, captured_q_ref, captured_q_dut;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,q_ref,q_dut );
	end

	
	wire tb_match; // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		.a,
		.b );
	RefModule good1 (
		.a,
		.b,
		.q(q_ref) );
	
	TopModule top_module1 (
		.a,
		.b,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
		endtask	
	
	// Helper task for formatted display
	task display_state;
		input bit ca, cb, cq_ref, cq_dut;
		input int t;
		begin
			$display("
========================================================");
			$display("!!! FIRST MISMATCH DETECTED !!!");
			$display("Time: %0d ps", t);
			$display("--------------------------------------------------------");
			$display("Input Signals: a = %b, b = %b", ca, cb);
			$display("Expected Output (q_ref): %b (Hex: %h)", cq_ref, cq_ref);
			$display("Actual Output (q_dut):   %b (Hex: %h)", cq_dut, cq_dut);
			$display("========================================================
");
		endtask
	
	
	final begin
		// Final reporting based on new requirements
		if (stats1.errors > 0)
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		else
			$display("SIMULATION PASSED");
		end
	
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		
		// Check for general mismatch
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture state for detailed reporting if this is the first error
				first_mismatch_captured = 1;
				display_state(a, b, q_ref, q_dut, $time);
			end
			s
			stats1.errors++;
		end
		
		// Original logic for q mismatch
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1;
		end
		end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule