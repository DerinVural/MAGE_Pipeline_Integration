`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator ---
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

// --- DUT Implementation (Based on K-map interpretation) ---
module TopModule (
    input logic [3:0] x,
    output logic f
);
		// Interpreting K-map: R = x[3]x[0], C = x[1]x[2]. Choosing 0 for 'd'.
		// (R=00, C=00)->0, (R=00, C=01)->0, (R=00, C=11)->0, (R=00, C=10)->0
		// (R=01, C=00)->0, (R=01, C=01)->0, (R=01, C=11)->1, (R=01, C=10)->0
		// (R=11, C=00)->1, (R=11, C=01)->1, (R=11, C=11)->0, (R=11, C=10)->0
		// (R=10, C=00)->1, (R=10, C=01)->1, (R=10, C=11)->0, (R=10, C=10)->0
		
		logic f_internal;
		
		// Logic derived from the table, assuming R=x[3]x[0] and C=x[1]x[2]
		assign f_internal = 
			 (x[3]==1'b0 && x[0]==1'b0 && x[1]==1'b0 && x[2]==1'b0) ? 1'b0 : // R=00, C=00 (d->0)
			 (x[3]==1'b0 && x[0]==1'b0 && x[1]==1'b0 && x[2]==1'b1) ? 1'b0 : // R=00, C=01 (0)
			 (x[3]==1'b0 && x[0]==1'b0 && x[1]==1'b1 && x[2]==1'b1) ? 1'b0 : // R=00, C=11 (d->0)
			 (x[3]==1'b0 && x[0]==1'b0 && x[1]==1'b1 && x[2]==1'b0) ? 1'b0 : // R=00, C=10 (d->0)
			 
			 (x[3]==1'b0 && x[0]==1'b1 && x[1]==1'b0 && x[2]==1'b0) ? 1'b0 : // R=01, C=00 (0)
			 (x[3]==1'b0 && x[0]==1'b1 && x[1]==1'b0 && x[2]==1'b1) ? 1'b0 : // R=01, C=01 (d->0)
			 (x[3]==1'b0 && x[0]==1'b1 && x[1]==1'b1 && x[2]==1'b1) ? 1'b1 : // R=01, C=11 (1)
			 (x[3]==1'b0 && x[0]==1'b1 && x[1]==1'b1 && x[2]==1'b0) ? 1'b0 : // R=01, C=10 (0)
			 
			 (x[3]==1'b1 && x[0]==1'b1 && x[1]==1'b0 && x[2]==1'b0) ? 1'b1 : // R=11, C=00 (1)
			 (x[3]==1'b1 && x[0]==1'b1 && x[1]==1'b0 && x[2]==1'b1) ? 1'b1 : // R=11, C=01 (1)
			 (x[3]==1'b1 && x[0]==1'b1 && x[1]==1'b1 && x[2]==1'b1) ? 1'b0 : // R=11, C=11 (d->0)
			 (x[3]==1'b1 && x[0]==1'b1 && x[1]==1'b1 && x[2]==1'b0) ? 1'b0 : // R=11, C=10 (d->0)
			 
			 (x[3]==1'b1 && x[0]==1'b0 && x[1]==1'b0 && x[2]==1'b0) ? 1'b1 : // R=10, C=00 (1)
			 (x[3]==1'b1 && x[0]==1'b0 && x[1]==1'b0 && x[2]==1'b1) ? 1'b1 : // R=10, C=01 (1)
			 (x[3]==1'b1 && x[0]==1'b0 && x[1]==1'b1 && x[2]==1'b1) ? 1'b0 : // R=10, C=11 (0)
			 (x[3]==1'b1 && x[0]==1'b0 && x[1]==1'b1 && x[2]==1'b0) ? 1'b0 : // R=10, C=10 (d->0)
		
		assign f = f_internal;
endmodule

// --- Testbench ---
module tb();
		typedef struct packed {
			int errors;
			int errortime;
			int errors_f;
			int errortime_f;
			int clocks;
			logic [3:0] first_mismatch_x;
			logic first_mismatch_ref_f;
			logic first_mismatch_dut_f;
		} stats;
		
		stats stats1;
		
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

		
		// Store data for detailed failure report
		always @(posedge clk, negedge clk) begin
			stats1.clocks++;
			
			if (!tb_match) begin
				if (stats1.errors == 0) {
					stats1.errortime = $time;
					stats1.first_mismatch_x = x;
					stats1.first_mismatch_ref_f = f_ref;
					stats1.first_mismatch_dut_f = f_dut;
				} else if (stats1.errors == 1) begin
				// Update captured values if we hit mismatch again, though only the first matters for reporting
				s
				stats1.first_mismatch_x = x;
				stats1.first_mismatch_ref_f = f_ref;
				stats1.first_mismatch_dut_f = f_dut;
				end
			stats1.errors++;
			end

			if (f_ref !== ( f_ref ^ f_dut ^ f_ref ))
			begin 
				if (stats1.errors_f == 0) stats1.errortime_f = $time;
				s
				s
				s
				stats1.first_mismatch_x = x;
				stats1.first_mismatch_ref_f = f_ref;
				stats1.first_mismatch_dut_f = f_dut;
				end
			stats1.errors_f = stats1.errors_f+1'b1;
			end
		end

		// Verification assignment remains the same
		assign tb_match = ( { f_ref } === ( { f_ref } ^ { f_dut } ^ { f_ref } ) );

		// Final reporting block
		final begin
			if (stats1.errors_f) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "f", stats1.errors_f, stats1.errortime_f);
				// Detailed failure report for f
				$display("============================================================");
				$display("SIMULATION FAILED - f MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime_f);
				$display("Time: %0d ps", stats1.errortime_f);
				$display("Inputs (x): HEX=%h, BIN=%b", stats1.first_mismatch_x, stats1.first_mismatch_x);
				$display("Expected Output (f_ref): HEX=%b", stats1.first_mismatch_ref_f);
				$display("Actual Output (f_dut): HEX=%b", stats1.first_mismatch_dut_f);
				$display("============================================================");
			end
			if (stats1.errors) begin
				// Detailed failure report for x (general mismatch)
				$display("============================================================");
				$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
				$display("Time: %0d ps", stats1.errortime);
				$display("Inputs (x): HEX=%h, BIN=%b", stats1.first_mismatch_x, stats1.first_mismatch_x);
				$display("Expected Output (f_ref): HEX=%b", stats1.first_mismatch_ref_f);
				$display("Actual Output (f_dut): HEX=%b", stats1.first_mismatch_dut_f);
				$display("============================================================");
			end
		
		if (!stats1.errors && !stats1.errors_f) begin
			$display("SIMULATION PASSED");
			end
		
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		end

   // add timeout after 100K cycles	
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule
