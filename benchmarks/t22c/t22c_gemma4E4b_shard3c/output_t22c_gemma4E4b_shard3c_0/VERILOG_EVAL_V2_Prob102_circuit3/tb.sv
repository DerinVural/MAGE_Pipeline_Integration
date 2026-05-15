`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		output logic a,b,c,d,
		output reg[511:0] wavedrom_title,
		output reg wavedrom_enable
);

		// Add two ports to module stimulus_gen:
		//    output [511:0] wavedrom_title
		//    output reg wavedrom_enable

		task wavedrom_start(input[511:0] title = "");
		endtask
		
		task wavedrom_stop;
			#1;
		endtask	

		initial begin
			{a,b,c,d} <= 0;
			@(negedge clk) wavedrom_start("Unknown circuit");
			@(posedge clk) {a,b,c,d} <= 0;
			repeat(18) @(posedge clk, negedge clk) {a,b,c,d} <= {a,b,c,d} + 1;
			wavedrom_stop();
			
			repeat(100) @(posedge clk, negedge clk)
				{a,b,c,d} <= $urandom;
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
		}
		stats;
		
		stats stats1;
		
		
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		// Corrected clock generation
		initial forever
			#5 clk = ~clk;

		logic a;
		logic b;
		logic c;
		logic d;
		logic q_ref;
		logic q_dut;

		// Variables to capture state at first mismatch
		logic first_mismatch_captured = 0;
		logic first_mismatch_a, first_mismatch_b, first_mismatch_c, first_mismatch_d;
		logic first_mismatch_q_ref, first_mismatch_q_dut;
		integer first_mismatch_time_captured = 0;
		
		initial begin 
			$dumpfile("wave.vcd");
			$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,q_ref,q_dut );
		end

		
		wire tb_match;        // Verification
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk,
			.* , 
			a,
			b,
			c,
			d );
		RefModule good1 (
			a,
			b,
			c,
			d,
			.q(q_ref) );
		
		TopModule top_module1 (
			a,
			b,
			c,
			d,
			.q(q_dut) );

		
		bit strobe = 0;
		
task wait_for_end_of_timestep;
			repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			endtask	

		final begin
			if (stats1.errors_q == 0) begin
			$display("SIMULATION PASSED");
			
			end
		else begin
			// Required failure format
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_q, stats1.errortime_q);
			$display("--- First Mismatch Details (q check) ---");
			$display("Time: %0d ps", stats1.errortime_q);
			// Display inputs: a, b, c, d
			$display("Inputs: a=%b, b=%b, c=%b, d=%b", first_mismatch_a, first_mismatch_b, first_mismatch_c, first_mismatch_d);
			// Display outputs: Q_Ref and Q_DUT. Since they are 1-bit, binary/hex is simple.
			$display("Outputs: Q_Ref=%b (0x%h), Q_DUT=%b (0x%h)", first_mismatch_q_ref, first_mismatch_q_ref, first_mismatch_q_dut, first_mismatch_q_dut);
			end

		$display("Simulation finished at %0d ps", $time);
		$display("Total mismatched samples (DUT vs Ref): %1d out of %1d samples", stats1.errors, stats1.clocks);
		$display("Total q mismatches: %1d out of %1d samples", stats1.errors_q, stats1.clocks);
		end

		// Verification check (Maintains original logic)
		assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
		
		// Main verification loop
		always @(posedge clk, negedge clk) begin
			
			stats1.clocks++;
			
			// Check for DUT vs RefModule mismatch
			if (!tb_match) begin
				if (stats1.errors == 0) begin
					stats1.errortime = $time;
					// Capture state for first DUT mismatch
					first_mismatch_captured = 1;
					first_mismatch_time_captured = $time;
					first_mismatch_a = a; first_mismatch_b = b; first_mismatch_c = c; first_mismatch_d = d;
					first_mismatch_q_ref = q_ref; first_mismatch_q_dut = q_dut;
				end
				sstats1.errors++;
			end
			
			// Check for q mismatch (Original logic maintained)
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