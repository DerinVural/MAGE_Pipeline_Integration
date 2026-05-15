`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg reset,
	input tb_match,
	output reg wavedrom_enable,
	output reg[511:0] wavedrom_title
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask

	task wavedrom_stop;
		#1;
	endtask

	task reset_test(input async=0);
		bit arfail, srfail, datafail;

		@(posedge clk);
		@(posedge clk) reset <= 0;
		repeat(3) @(posedge clk);

		@(negedge clk) begin datafail = !tb_match ; reset <= 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
		srfail = !tb_match;
		reset <= 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

	initial begin
		reset <= 1;
		@(negedge clk);

		wavedrom_start("Reset and counting");
		reset_test();

		repeat(3) @(posedge clk);
		wavedrom_stop();

		repeat(400) @(posedge clk, negedge clk) begin
		reset <= !($random & 31);
		end
		#1 $finish;
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
		#5 clk = ~clk;

	logic reset;
	logic [3:0] q_ref;
	logic [3:0] q_dut;

	// Signals to capture at first mismatch time
	logic [3:0] q_dut_at_error;
	logic [3:0] q_ref_at_error;
	logic clk_at_error;
	logic reset_at_error;

	initial begin
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen::stim1, tb_mismatch ,clk,reset,q_ref,q_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;

	stimulus_gen stim1 (
		.clk, 
		.* , 
		.reset );
	RefModule good1 (
		.clk,
		.reset,
		.q(q_ref) );

	TopModule top_module1 (
		.clk,
		.reset,
		.q(q_dut) );

	
	bit strobe = 0;
		task wait_for_end_of_timestep;
			repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			end
		task

	initial begin
		// Initialize error capture signals
		q_dut_at_error = 4'bx;
		q_ref_at_error = 4'bx;
		clk_at_error = 1'bx;
		reset_at_error = 1'bx;

		// Wait for initial stable state before testing starts seriously
		repeat(5) @(posedge clk);
		$display("--- Simulation Start ---");
	end

	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;

		// Check for general mismatch (tb_match)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			// Capture state at first general mismatch
			q_dut_at_error <= q_dut;
			q_ref_at_error <= q_ref;
			clk_at_error <= clk;
			reset_at_error <= reset;
			sstats1.errors++;
		end

		// Check for q specific mismatch (errors_q)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			// Capture state at first Q mismatch
			q_dut_at_error <= q_dut;
			q_ref_at_error <= q_ref;
			clk_at_error <= clk;
			reset_at_error <= reset;
			sstats1.errors_q = stats1.errors_q+1'b1;
		end
		end
	
	end

	// Add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	final begin
		$display("==================================================");

		// 1. Check for Q specific mismatch first (highest priority failure)
		if (stats1.errors_q > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_q, stats1.errortime_q);
			$display("--- FIRST Q MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime_q);
			// Display inputs
			$display("Inputs: CLK=%b, RESET=%b", clk_at_error, reset_at_error);
			// Display outputs (Q is 4 bits <= 64, so display HEX and BIN)
			$display("Outputs: DUT_Q=%h (%b), REF_Q=%h (%b)", q_dut_at_error, q_dut_at_error, q_ref_at_error, q_ref_at_error);
		end

		// 2. Check for general mismatch if no Q mismatch occurred
		if (stats1.errors > 0 && stats1.errors_q == 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
			$display("--- FIRST GENERAL MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
			// Display inputs
			$display("Inputs: CLK=%b, RESET=%b", clk_at_error, reset_at_error);
			// Display outputs (Q is 4 bits <= 64, so display HEX and BIN)
			$display("Outputs: DUT_Q=%h (%b), REF_Q=%h (%b)", q_dut_at_error, q_dut_at_error, q_ref_at_error, q_ref_at_error);
		end

		// 3. Success condition
		if (stats1.errors == 0 && stats1.errors_q == 0) begin
			$display("SIMULATION PASSED");
		end

		$display("==================================================");
		$display("Summary: Total mismatched samples (tb_match) is %0d out of %0d samples.", stats1.errors, stats1.clocks);
		$display("Summary: Total Q specific mismatched samples is %0d out of %0d samples.", stats1.errors_q, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("==================================================");
	end

endmodule