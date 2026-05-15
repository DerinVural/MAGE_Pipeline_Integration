/*
 * The interface for TopModule is derived from the golden testbench structure,
 * as per the instructions, even if it contradicts the minimal spec.
 */

`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg reset
);

	initial begin
		repeat(100) @(negedge clk) begin
			reset <= !($random & 31);
		end
		
		#1 $finish;
	end
	endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_shift_ena;
		int errortime_shift_ena;
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
logic shift_ena_ref;
logic shift_ena_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,shift_ena_ref,shift_ena_dut );
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
		.shift_ena(shift_ena_ref) );
	
TopModule top_module1 (
		.clk,
		.reset,
		.shift_ena(shift_ena_dut) );

	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task
	
	logic first_mismatch_logged = 0;

	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			
			// Display FIRST MISMATCH
			if (first_mismatch_logged == 0) begin
				$display("\n=======================================================");
				$display("FIRST MISMATCH DETECTED AT TIME %0d ps", $time);
				$display("--------------------------------------------------------");
				$display("Input Signals:");
				$display("  clk: %b", clk);
				$display("  reset: %b", reset);
				$display("Output Signals:");
				$display("  shift_ena (Actual/DUT): %b (HEX: %h)", shift_ena_dut, shift_ena_dut);
				$display("  shift_ena (Expected/Ref): %b (HEX: %h)", shift_ena_ref, shift_ena_ref);
				$display("======================================================\n");
				first_mismatch_logged = 1;
			end
			endif
		endif
		stats1.errors++;
		
		// Original error counting for shift_ena specific check
		if (shift_ena_ref !== ( shift_ena_ref ^ shift_ena_dut ^ shift_ena_ref ))
		begin 
			if (stats1.errors_shift_ena == 0) stats1.errortime_shift_ena = $time;
			stats1.errors_shift_ena = stats1.errors_shift_ena+1'b1; 
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	final begin
		// Check for any errors to determine the final output message
		if (stats1.errors > 0 || stats1.errors_shift_ena > 0) begin
			// Use the earliest mismatch time found (stats1.errortime)
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end else begin
			$display("SIMULATION PASSED");
		end
		$display("Simulation finished at %0d ps", $time);
		$display("Total Mismatches (General): %1d in %1d samples", stats1.errors, stats1.clocks);
		$display("Total Mismatches (shift_ena specific): %1d", stats1.errors_shift_ena);
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { shift_ena_ref } === ( { shift_ena_ref } ^ { shift_ena_dut } ^ { shift_ena_ref } ) );

endmodule