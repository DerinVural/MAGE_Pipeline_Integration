`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen(
		input clk,
		output logic areset,
		output logic train_valid,
		output logic train_taken,
		input tb_match,
		output reg[511:0] wavedrom_title,
		output reg wavedrom_enable,
		out int wavedrom_hide_after_time
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

		task wavedrom_start(input[511:0] title = "");
	endtask
		task wavedrom_stop;
			#1;
		endtask

		reg reset;
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

		
		assign areset = reset;
		logic train_taken_r;
		assign train_taken = train_valid ? train_taken_r : 1'bx;
		
		initial begin
			@(posedge clk);
			@(posedge clk) reset <= 1;
			@(posedge clk) reset <= 0;
			train_taken_r <= 1;
			train_valid <= 1;
			
			wavedrom_start("Asynchronous reset");
			reset_test(1); // Test for asynchronous reset
			wavedrom_stop();
			@(posedge clk) reset <= 1;
			train_taken_r <= 1;
			train_valid <= 0;
			@(posedge clk) reset <= 0;

			wavedrom_start("Count up, then down");
			train_taken_r <= 1;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 0;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 0;
				@(posedge clk) train_valid <= 1;
			train_taken_r <= 0;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 0;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 1;
				@(posedge clk) train_valid <= 0;
				@(posedge clk) train_valid <= 1;		wavedrom_stop();

			repeat(1000) @(posedge clk,negedge clk) 
			{train_valid, train_taken_r} <= {$urandom} ;
		
			#1 $finish;
		end
		endmodule

module tb();

		typedef struct packed {
			int errors;
			int errortime;
			int errors_state;
			int errortime_state;

			int clocks;
		// Fields to capture at first error
		logic clk_err;
		logic areset_err;
		logic train_valid_err;
		logic train_taken_err;
		logic [1:0] state_ref_err;
		logic [1:0] state_dut_err;
	}	stats;
		
		stats stats1;
		
		
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		initial forever
			#5 clk = ~clk;
		end

		logic areset;
		logic train_valid;
		logic train_taken;
		logic [1:0] state_ref;
		logic [1:0] state_dut;

		initial begin 
			$dumpfile("wave.vcd");
			$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,train_valid,train_taken,state_ref,state_dut );
		end

		
		wire tb_match;
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk, 
			areset, 
			train_valid, 
			train_taken, 
			tb_match, 
			wavedrom_title, 
			wavedrom_enable, 
			wavedrom_hide_after_time
		);
		RefModule good1 (
			.clk, 
			areset, 
			train_valid, 
			train_taken, 
			.state(state_ref) );
		
		TopModule top_module1 (
			.clk, 
			areset, 
			train_valid, 
			train_taken, 
			.state(state_dut) );

		
		bit strobe = 0;
			task wait_for_end_of_timestep;
				repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			endtask
		
			// Helper task to display signals in HEX/BIN format
			task display_signals;
				$display("=======================================================================================");
				$display("--- MISMATCH DETECTED AT TIME %0t ps ---", $time);
				$display("--- INPUT SIGNALS ---");
				$display("clk:   %h (%b)", clk, clk);
				$display("areset: %h (%b)", areset, areset);
				$display("train_valid: %h (%b)", train_valid, train_valid);
				$display("train_taken: %h (%b)", train_taken, train_taken);
				$display("--- OUTPUT SIGNALS ---");
				$display("state_DUT: %h (%b)", state_dut, state_dut);
				$display("state_REF: %h (%b)", state_ref, state_ref);
				$display("=======================================================================================");
			endtask

			final begin
				if (stats1.errors == 0 && stats1.errors_state == 0)
				$display("SIMULATION PASSED");
				
				// Original summary printout
				$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
				if (stats1.errors > 0)
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
				
				// Display details of the first mismatch if errors occurred
				if (stats1.errors > 0) begin
					sdisplay_signals();
				end
				
				$display("Simulation finished at %0d ps", $time);
				$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
			end

			// Verification: Simple equality check
			assign tb_match = (state_ref === state_dut);
			
			// Use explicit sensitivity list here.
			always @(posedge clk, negedge clk) begin
				
				stats1.clocks++;
				
				if (!tb_match) begin
					if (stats1.errors == 0) {
						sstats1.errortime = $time;
						// Capture signals at the time of first mismatch
						sstats1.clk_err = clk;
						sstats1.areset_err = areset;
						sstats1.train_valid_err = train_valid;
						sstats1.train_taken_err = train_taken;
						sstats1.state_ref_err = state_ref;
						sstats1.state_dut_err = state_dut;
					}
					sstats1.errors++;
				end
				
				// Check for state mismatch (Original logic maintained)
				if (state_ref !== state_dut) 
				begin 
					if (stats1.errors_state == 0) stats1.errortime_state = $time;
					sstats1.errors_state = stats1.errors_state+1'b1; 
				end
				end
			end

			// add timeout after 100K cycles
			initial begin
				#1000000
				$display("TIMEOUT");
				$finish();
			end
		endmodule


// Placeholder modules needed for compilation based on golden_testbench structure
module RefModule (
		input logic clk,
		input logic areset,
		input logic train_valid,
		input logic train_taken,
		output logic [1:0] state
);
		// Dummy implementation
		assign state = 2'b00;
	endmodule

module TopModule (
		input logic clk,
		input logic areset,
		input logic train_valid,
		input logic train_taken,
		output logic [1:0] state
);
		// Implementation based on specification
		logic [1:0] counter;
		
		// Initialization is mostly irrelevant as reset handles the starting state, but kept for structure.
		initial begin
			counter = 2'b00;
		end
		
		// Sequential Logic (Asynchronous Reset)
		always @(posedge clk or posedge areset) begin
			if (areset) begin
				// Reset to weakly not-taken (2'b01)
				counter <= 2'b01;
			end else begin
				// Standard clocked behavior
				if (train_valid) begin
					if (train_taken) begin
					// Increment, saturating at 3 (11)
					if (counter < 2'b11) begin
						counter <= counter + 1;
					end
				end else begin
					// Decrement, saturating at 0 (00)
					if (counter > 2'b00) begin
						counter <= counter - 1;
					end
				end
			end
			// If train_valid == 0, the counter holds its value (implicit)
		end
		
		// Output assignment
		assign state = counter;
	endmodule