`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg slowena,
	output reg reset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);

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
		s$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
		s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask
	
	
	reg hint1;
	initial begin
		reset <= 1;
		slowena <= 1;
		wavedrom_start("Synchronous reset and counting.");
		reset_test();
		repeat(12) @(posedge clk);
		wavedrom_stop();
		@(posedge clk);

		//wavedrom_start("Testing.");
		reset <= 1;
		@(posedge clk);
		reset <= 0;
		repeat(9) @(posedge clk);
		slowena <= 0;
		@(negedge clk) hint1 = tb_match;
		repeat(3) @(posedge clk);
		if (hint1 && !tb_match) begin
		s$display ("Hint: What is supposed to happen when the counter is 9 and not enabled?");
		end
		//wavedrom_stop();
		slowena <= 1;
		reset <= 1;
		@(posedge clk);
		reset <= 0;

		wavedrom_start("Enable/disable");
		repeat(15) @(posedge clk) slowena <= !(\$random & 1);
		wavedrom_stop();
		@(posedge clk);

		repeat(400) @(posedge clk, negedge clk) begin
		slowena <= !(\$random&3);
		reset <= !(\$random & 31);
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
		h#5 clk = ~clk;

	logic slowena;
	logic reset;
	logic [3:0] q_ref;
	logic [3:0] q_dut;

	// Signals to capture state at first error
	logic clk_capture;
	logic reset_capture;
	logic slowena_capture;
	logic [3:0] q_ref_capture;
	logic [3:0] q_dut_capture;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,slowena,reset,q_ref,q_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.slowena,
		.reset,
		.wavedrom_title,
		.wavedrom_enable,
		.tb_match
);
		
	RefModule good1 (
		.clk,
		slowena,
		.reset,
		.q(q_ref) );
		
	TopModule top_module1 (
		.clk,
		slowena,
		.reset,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask

	
	// Task to display detailed error information at the first mismatch
	task display_error_details;
		$display("======================================================================================");
		$display("!!! FIRST MISMATCH DETECTED !!!");
		$display("Time of mismatch: %0t ps", $time);
		$display("--- Input Signals ---");
		$display("CLK:     %b", clk_capture);
		$display("RESET:   %b", reset_capture);
		$display("SLOWENA: %b", slowena_capture);
		$display("--- Output Signals ---");
		$display("Q DUT (Actual): HEX=%h, BIN=%b", q_dut_capture, q_dut_capture);
		$display("Q REF (Expected): HEX=%h, BIN=%b", q_ref_capture, q_ref_capture);
		$display("======================================================================================");
	endtask
	
	
	final begin
		if (stats1.errors == 0) begin
			$display("\n**************************************");
			$display("SIMULATION PASSED");
			$display("**************************************");
		end else begin
			$display("\n**************************************");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("**************************************");
		end
		
		$display("Simulation finished at %0d ps", $time);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			$display("\n[ERROR DETECTED] Clock cycle %0d", stats1.clocks);
			sstats1.errortime = $time;
			// Capture state at first error
			clk_capture = clk;
			slowena_capture = slowena;
			reset_capture = reset;
			q_ref_capture = q_ref;
			q_dut_capture = q_dut;
			display_error_details();
			end
			stats1.errors++;
		end
		
		// Original logic for q mismatch (keeping it for count tracking if desired, though tb_match covers this)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1; 
		end
		end
	
	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		f$finish();
	end

	endmodule
