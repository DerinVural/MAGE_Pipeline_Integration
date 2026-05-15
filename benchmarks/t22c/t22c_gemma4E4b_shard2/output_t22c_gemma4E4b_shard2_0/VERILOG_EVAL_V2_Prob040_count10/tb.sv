`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
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
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
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
	
	
	initial begin
		reset <= 1;
		wavedrom_start("Synchronous reset and counting");
		reset_test();
		repeat(12) @(posedge clk);
		wavedrom_stop();
		@(posedge clk);
		
		repeat(400) @(posedge clk, negedge clk) begin
		reset <= !($random & 31);
		end
		#1 $finish;
	end
	
endmodule

module RefModule (
    input logic clk,
    input logic reset,
    output logic [3:0] q
);
    // Assuming RefModule implements the correct decade counter (0-9)
    always @(posedge clk)
    begin
        if (reset)
            q <= 4'b0000;
        else
            // Corrected logic to ensure wrap around from 9 to 0
            if (q == 4'd9)
                q <= 4'b0000;
            else
                q <= q + 1'b1;
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


logic reset;
logic [3:0] q_ref;
logic [3:0] q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,q_ref,q_dut );
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
		endtask
	

	// Task to display signals in HEX and BIN format
	task display_signals(input $time t, input logic [3:0] expected, input logic [3:0] actual);
		$display("
========================================================");
		$display("*** FIRST MISMATCH DETECTED *** at Time: %0d ps", t);
		$display("--------------------------------------------------------");
		$display("Input Signals at Time %0d ps:", t);
		$display("  clk: %b", clk);
		$display("  reset: %b", reset);
		$display("--------------------------------------------------------");
		$display("Output Signals at Time %0d ps:", t);
		$display("  Expected (q_ref): HEX=%h, BIN=%b", expected, expected);
		$display("  Actual (q_dut):   HEX=%h, BIN=%b", actual, actual);
		$display("========================================================");
	endtask
	
	
// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
	
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture and display signals ONLY when the first mismatch happens
				display_signals($time, q_ref, q_dut);
				stats1.errors_q = 1;
			end
		stats1.errors++;
		end
		
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1; 
		end
		end

end

// add timeout after 100K cycles
initial begin
  #1000000
  $display("TIMEOUT");
  $finish();
end


final begin
	// Check for total success or failure based on error counters
	if (stats1.errors == 0 && stats1.errors_q == 0)
		$display("SIMULATION PASSED");
	else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	end
	
	$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end

endmodule