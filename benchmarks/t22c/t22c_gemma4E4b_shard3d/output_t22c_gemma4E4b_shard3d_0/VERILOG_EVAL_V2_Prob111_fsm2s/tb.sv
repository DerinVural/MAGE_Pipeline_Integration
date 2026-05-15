`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic j, k,
	output logic reset,
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
		a functionality error than the reset being implemented asynchronously.
		endtask


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");	endtask
	task wavedrom_stop;
		#1;
	endtask

		reg [0:11][1:0] d = 24'b000101010010101111111111;
		
		initial begin
		reset <= 1;
	j <= 0;
	k <= 0;
		@(posedge clk);
		reset <= 0;
	j <= 1;
		@(posedge clk);
	j <= 0;
		wavedrom_start("Reset and transitions");
		reset_test();
		for (int i=0;i<12;i++) 
			@(posedge clk) {k, j} <= d[i];
		wavedrom_stop();
		repeat(200) @(posedge clk, negedge clk) begin
		{j,k} <= $random;
		reset <= !($random & 7);
		end

		#1 $finish;
		end
	endmodule

module tb();

	typedef struct packed {
	int errors;
	int errortime;
	int errors_out;
	int errortime_out;
	int clocks;
}
	stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;


logic j;
logic k;
logic reset;
logic out_ref;
logic out_dut;

	// Variables to capture failing state for detailed output
logic [3:0] captured_inputs_fail_gen = 4'b0;
logic captured_outputs_fail_gen = 0;
logic [3:0] captured_inputs_fail_out = 4'b0;
logic captured_outputs_fail_out = 0;
int fail_time_gen = -1;
int fail_time_out = -1;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,j,k,reset,out_ref,out_dut );
	end

	
wire tb_match;
wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.j, 
		.k, 
		.reset, 
		.tb_match
);
	RefModule good1 (
		.clk, 
		j, 
		k, 
		.reset, 
		.out(out_ref) );
	
	TopModule top_module1 (
		.clk, 
		j, 
		k, 
		.reset, 
		.out(out_dut) );
	
	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	// Helper task to display state information formatted as required
task display_mismatch_state(int time_val, logic [3:0] inputs_val, logic expected_out, logic actual_out, string failure_type);
		
		begin
			s$display("\n=======================================================================");
			s$display("SIMULATION FAILED - 1 MISMATCHES DETECTED, FIRST AT TIME %0d", time_val);
			s$display("Type: %s", failure_type);
			s$display("-----------------------------------------------------------------------");
			s$display("Input Signals:");
			// Inputs are {clk, reset, j, k}
			$display("  clk: %b", inputs_val[0]);
			$display("  reset: %b", inputs_val[1]);
			$display("  j: %b", inputs_val[2]);
			$display("  k: %b", inputs_val[3]);
			s$display("Output Signals:");
			// Output is 1 bit
			$display("  Expected (out_ref): %h (%b)", expected_out, expected_out);
			$display("  Actual (out_dut):   %h (%b)", actual_out, actual_out);
			s$display("=======================================================================\n");
		endtask
	
	
final begin
		int total_errors = stats1.errors + stats1.errors_out;
	int first_mismatch_time = -1;
	
		if (stats1.errors_out > 0) begin 
			// Output mismatch tracking
			int current_out_time = stats1.errortime_out;
			if (current_out_time != -1) {
				display_mismatch_state(current_out_time, 
					{clk, reset, j, k}, out_ref, "OUTPUT MISMATCH");
				first_mismatch_time = current_out_time;
			}
			// Fallthrough to general reporting if output failure time is not the earliest
			if (stats1.errors > 0 && stats1.errortime != -1 && stats1.errortime < (first_mismatch_time == -1 ? 9999999 : first_mismatch_time)) begin
				display_mismatch_state(stats1.errortime, 
					{clk, reset, j, k}, out_ref, "GENERAL MISMATCH");
				first_mismatch_time = stats1.errortime;
			}
			// Final required summary output
			if (first_mismatch_time != -1) begin
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_errors, first_mismatch_time);
				$display("-----------------------------------------------------------------------");
				$display("Final Summary:");
				$display("Total mismatched samples: %0d out of %0d samples", stats1.errors, stats1.clocks);
				$display("Simulation finished at %0d ps", $time);
				$display("-----------------------------------------------------------------------");
			end
		
		end
		
		// General mismatch tracking (based on tb_match)
		if (stats1.errors > 0 && stats1.errortime != -1) begin
			// Only report general mismatch if it was earlier than any detected output mismatch, or if errors_out was 0.
			if (stats1.errors_out == 0 || stats1.errortime < (stats1.errortime_out == -1 ? 9999999 : stats1.errortime_out)) begin
				display_mismatch_state(stats1.errortime, 
					{clk, reset, j, k}, out_ref, "GENERAL MISMATCH");
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
				$display("-----------------------------------------------------------------------");
				$display("Final Summary:");
				$display("Total mismatched samples: %0d out of %0d samples", stats1.errors, stats1.clocks);
				$display("Simulation finished at %0d ps", $time);
				$display("-----------------------------------------------------------------------");
			end
		end
		
		// Success case
		if (stats1.errors == 0 && stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
			$display("-----------------------------------------------------------------------");
			$display("Final Summary:");
			$display("Total mismatched samples: %0d out of %0d samples", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
			$display("-----------------------------------------------------------------------");
		end
		end
	
	// Verification
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

// Use explicit sensitivity list here.

always @(posedge clk, negedge clk) begin
	
	stats1.clocks++;
	
	// General mismatch tracking (based on tb_match)
	if (!tb_match) begin
		if (stats1.errors == 0)
			sstats1.errortime = $time;
			// Capture state at first general mismatch
			captured_inputs_fail_gen = {clk, reset, j, k};
			fail_time_gen = $time;
			end
		stats1.errors++;
		end
	
	// Specific output mismatch tracking
	if (out_ref !== out_dut) // Simplified logic for comparison
		begin 
			if (stats1.errors_out == 0)
			sstats1.errortime_out = $time;
			// Capture state at first output mismatch
			captured_inputs_fail_out = {clk, reset, j, k};
			fail_time_out = $time;
			end
		stats1.errors_out = stats1.errors_out+1'b1;
		end
	endmodule