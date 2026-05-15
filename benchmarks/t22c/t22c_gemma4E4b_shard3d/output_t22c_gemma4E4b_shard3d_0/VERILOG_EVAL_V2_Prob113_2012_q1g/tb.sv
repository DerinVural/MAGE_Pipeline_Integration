`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Placeholder for RefModule as it is used in the golden testbench
module RefModule (
    input logic [3:0] x,
    output logic f
);
    // Simple reference logic matching the K-map for correctness comparison
    // (Assuming RefModule implements the same logic as TopModule for verification setup)
    assign f = (x == 4'b0000) | (x == 4'b1000) | (x == 4'b1001) | (x == 4'b1010) | (x == 4'b1100) | (x == 4'b1101) | (x == 4'b1111) | (x == 4'b1011); 
endmodule

module stimulus_gen (
	input clk,
	output logic [3:0] x
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
		x <= $random;
		end
		#1 $finish;
	end
	endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_f;
		int errortime_f;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Variables to store first mismatch details as required by the new prompt
	logic [3:0] x_first_mismatch_tb;
	logic f_ref_first_mismatch_tb;
	logic f_dut_first_mismatch_tb;
	int time_first_mismatch_tb = -1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [3:0] x;
	logic f_ref;
	logic f_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,x,f_ref,f_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.x );
	RefModule good1 (
		.x,
		.f(f_ref) );
	
	TopModule top_module1 (
		.x,
		.f(f_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	endtask
	
	// --- Final Check Logic (Improved based on new requirements) ---
	initial begin
		// Wait for stimulus_gen timeout or simulation end
		wait (stim1.x == 4'b1111 && $time > 10000); // Wait for some time to allow stimulus to run
		#1000000 // Wait until the safety timeout

		if (stats1.errors > 0 || stats1.errors_f > 0) begin
			$display("============================================================")
			$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", time_first_mismatch_tb);

			// Display details for the first overall mismatch (tb_mismatch)
			if (time_first_mismatch_tb != -1) begin
				$display("\n--- First Mismatch Details (Overall tb_mismatch) ---");
				$display("Time: %0d ps", time_first_mismatch_tb);
				$display("Input x: HEX=%h, BIN=%b", x_first_mismatch_tb, x_first_mismatch_tb);
				$display("Expected f_ref: HEX=%b", f_ref_first_mismatch_tb);
				$display("Actual f_dut: HEX=%b", f_dut_first_mismatch_tb);
				$display("--------------------------------------------------");
			end

			// Display details specifically for the first f_ref mismatch
		if (stats1.errors_f > 0) begin
				$display("\n--- First Mismatch Details (f_ref comparison) ---");
				$display("Time: %0d ps", stats1.errortime_f);
				// Use the recorded state from the first error time if available, otherwise use current state
				$display("Input x: HEX=%h, BIN=%b", x, x);
				$display("Expected f_ref: HEX=%b", f_ref);
				$display("Actual f_dut: HEX=%b", f_dut);
				$display("--------------------------------------------------");
			end
			$display("============================================================")
			$display("Total mismatched samples: %0d out of %0d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
			$display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
			$finish;
		end else begin
			$display("============================================================")
			$display("SIMULATION PASSED")
			$display("============================================================")
			$finish;
		end
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { f_ref } === ( { f_ref } ^ { f_dut } ^ { f_ref } ) );

	// Sensitivity list must be broad to capture changes during clock edges
always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// --- Overall Mismatch Tracking (tb_mismatch) ---
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				time_first_mismatch_tb = $time;
				x_first_mismatch_tb = x;
				f_ref_first_mismatch_tb = f_ref;
				f_dut_first_mismatch_tb = f_dut;
			end
			s1.errors++;
		end
		
		// --- f_ref comparison Mismatch Tracking (f_ref vs DUT) ---
		if (f_ref !== ( f_ref ^ f_dut ^ f_ref ))
		begin 
			if (stats1.errors_f == 0) stats1.errortime_f = $time;
			s1.errors_f = stats1.errors_f+1'b1;
		end
	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT REACHED");
     $finish();
   end
	endmodule