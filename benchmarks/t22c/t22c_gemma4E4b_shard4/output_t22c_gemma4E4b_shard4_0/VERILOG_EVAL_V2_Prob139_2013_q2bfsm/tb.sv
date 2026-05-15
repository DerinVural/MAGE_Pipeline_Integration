`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Stimulus Generator (Kept as is, as per requirement 1 & 2)
module stimulus_gen (
	input clk,
	output logic resetn,
	output logic x, y
);
		initial begin
			resetn = 0;
			x = 0;
			y = 0;
			@(posedge clk);
			@(posedge clk);
			resetn = 1;
			repeat(500) @(negedge clk) begin
				resetn <= ($random & 31) != 0;
				{x,y} <= $random;
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
			int errors_g;
			int errortime_g;
			int clocks;
		} stats;
		
		stats stats1;
		
		// Signal storage for first error logging
		logic log_clk, log_resetn, log_x, log_y, log_f_ref, log_f_dut, log_g_ref, log_g_dut;
		
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		initial forever
			#5 clk = ~clk;

		logic resetn;
		logic x;
		logic y;
		logic f_ref;
		logic f_dut;
		logic g_ref;
		logic g_dut;

		initial begin 
			$dumpfile("wave.vcd");
			// Added all signals for comprehensive dumping
			$dumpvars(1, stim1.clk, tb, clk, resetn, x, y, f_ref, f_dut, g_ref, g_dut, log_clk, log_resetn, log_x, log_y, log_f_ref, log_f_dut, log_g_ref, log_g_dut );
		end

		wire tb_match;
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk, 
			.resetn, // Note: Golden TB used .* here, but explicit mapping is safer
			.x, 
			.y 
		);
		RefModule good1 (
			.clk, 
			.resetn,
			.x,
			.y,
			.f(f_ref),
			.g(g_ref) );
		
		TopModule top_module1 (
			.clk,
			.resetn,
			.x,
			.y,
			.f(f_dut),
			.g(g_dut) );

		
		bit strobe = 0;
		task wait_for_end_of_timestep;
			repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			end
		endtask

		// Task to log state when the first mismatch occurs
		task log_mismatch_state;
		begin
			log_clk = clk;
			log_resetn = resetn;
			log_x = x;
			log_y = y;
			log_f_ref = f_ref;
			log_f_dut = f_dut;
			log_g_ref = g_ref;
			log_g_dut = g_dut;
		end
		endtask

		final begin
			$display("=======================================================");
			$display("SIMULATION SUMMARY");
			$display("=======================================================");
			
			if (stats1.errors == 0) begin
				$display("SIMULATION PASSED");
			end else begin
				$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
				$display("\n--- STATE AT FIRST MISMATCH (TIME %0d ps) ---", stats1.errortime);
				$display("Inputs: clk=%b, resetn=%b, x=%b, y=%b", log_clk, log_resetn, log_x, log_y);
				$display("Outputs: f_expected=%b, f_actual=%b, g_expected=%b, g_actual=%b", log_f_ref, log_f_dut, log_g_ref, log_g_dut);
				$display("-------------------------------------------------------");
			end
			
			$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
		end

		// Verification Logic
		// Original XOR assignment (kept for functionality integrity)
		assign tb_match = ( { f_ref, g_ref } === ( { f_ref, g_ref } ^ { f_dut, g_dut } ^ { f_ref, g_ref } ) );
		
		// State monitoring and error counting
		always @(posedge clk, negedge clk) begin
			// Resetting logs on reset pulse (if we were to implement a proper state reset, but following original structure)
			if (!resetn) begin
				stats1.clocks = 0;
				stats1.errors = 0;
				stats1.errors_f = 0;
				stats1.errors_g = 0;
				stats1.errortime = 0;
				stats1.errortime_f = 0;
				stats1.errortime_g = 0;
				end
			else begin
				stats1.clocks++;
				
				// Overall Mismatch Check
				if (!tb_match) begin
					if (stats1.errors == 0) stats1.errortime = $time; // Record time of FIRST mismatch
					// Log current state if this is the first error detected
					if (stats1.errors == 0) log_mismatch_state();
				stats1.errors++;
				end
				
				// F Output Check
			if (f_ref !== ( f_ref ^ f_dut ^ f_ref ))
				begin 
					if (stats1.errors_f == 0) stats1.errortime_f = $time;
					// Log current state if this is the first F error detected
					if (stats1.errors_f == 0) log_mismatch_state(); 
				stats1.errors_f = stats1.errors_f+1'b1; 
				end
				
				// G Output Check
			if (g_ref !== ( g_ref ^ g_dut ^ g_ref ))
				begin 
					if (stats1.errors_g == 0) stats1.errortime_g = $time;
					// Log current state if this is the first G error detected
					if (stats1.errors_g == 0) log_mismatch_state();
				stats1.errors_g = stats1.errors_g+1'b1; 
				end
			end
		end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED. Forcing simulation end.");
     $finish();
   end

endmodule