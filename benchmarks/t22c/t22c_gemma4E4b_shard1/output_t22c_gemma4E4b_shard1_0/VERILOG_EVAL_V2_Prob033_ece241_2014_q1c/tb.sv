`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		output logic [7:0] a, b,
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
			{a, b} <= 0;
			@(negedge clk) wavedrom_start();
				@(posedge clk) {a, b} <= 16'h0;
				@(posedge clk) {a, b} <= 16'h0070;
				@(posedge clk) {a, b} <= 16'h7070;
				@(posedge clk) {a, b} <= 16'h7090;
				@(posedge clk) {a, b} <= 16'h9070;
				@(posedge clk) {a, b} <= 16'h9090;
				@(posedge clk) {a, b} <= 16'h90ff;
			@(negedge clk) wavedrom_stop();
			repeat(100) @(posedge clk, negedge clk)
				{a,b} <= $random;

			$finish;
		end

endmodule

module tb();

		typedef struct packed {
			int errors;
			int errortime;
			int errors_s;
			int errortime_s;
			int errors_overflow;
			int errortime_overflow;
			int clocks;
		} stats;
		
		stats stats1;
		
		
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		// Corrected clock generation using always block
		always #5 clk = ~clk;

		logic [7:0] a;
		logic [7:0] b;
		logic [7:0] s_ref;
		logic [7:0] s_dut;
		logic overflow_ref;
		logic overflow_dut;

		// Variables to capture first mismatch details
		logic mismatch_s_first_hit = 0;
		logic mismatch_overflow_first_hit = 0;
		
		initial begin 
			$dumpfile("wave.vcd");
			$dumpvars(1, stim1.clk, tb_mismatch ,a,b,s_ref,s_dut,overflow_ref,overflow_dut );
		end

		
		wire tb_match;		// Verification
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk,
			.* ,
			.a,
			.b );
		
		// Assuming RefModule exists and matches the interface from the specification context
		RefModule good1 (
			.a,
			.b,
			s(s_ref),
			.overflow(overflow_ref) );
		
		TopModule top_module1 (
			.a,
			.b,
			s(s_dut),
			.overflow(overflow_dut) );

		
		bit strobe = 0;
		// Task wait_for_end_of_timestep retained for functional match, though unused in verification loop
		task wait_for_end_of_timestep;
			repeat(5) begin
				strobe <= !strobe;  // Try to delay until the very end of the time step.
				@(strobe);
			end
			endtask

		// Task to display detailed mismatch information for the first error
		task display_mismatch_details;
			input int mismatch_type;
			input int current_time;
			
			$display("\n========================================================================\n");
			$display("!!! FIRST MISMATCH DETECTED !!! (Type: %s)", (mismatch_type == 1 ? "s" : "overflow"));
			$display("Time: %0d ps", current_time);
			$display("------------------------------------------------------------------------");
			$display("INPUTS:");
			// Display in HEX and BIN format as required
			$display("  a: HEX=%h, BIN=%b", a, a);
			$display("  b: HEX=%h, BIN=%b", b, b);
			$display("OUTPUTS (DUT):");
			$display("  s: HEX=%h, BIN=%b", s_dut, s_dut);
			$display("  overflow: DUT=%b", overflow_dut);
			$display("EXPECTED (REF):");
			$display("  s: HEX=%h, BIN=%b", s_ref, s_ref);
			$display("  overflow: REF=%b", overflow_ref);
			$display("========================================================================\n");
		endtask

		final begin
			if (stats1.errors == 0) begin
				$display("SIMULATION PASSED");
			end else begin
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			end
		end
		
		// Verification check
		assign tb_match = ( { s_ref, overflow_ref } === { s_dut, overflow_dut } );
		
		// Always block for checking and counting errors
		always @(posedge clk, negedge clk) begin
			
			stats1.clocks++;
			
			// Update total errors
			if (!tb_match) begin
				if (stats1.errors == 0) stats1.errortime = $time;
				stats1.errors++;
			end
			
			// Check 's' mismatch
			if (s_ref !== s_dut) begin
				if (stats1.errors_s == 0) begin
				stats1.errortime_s = $time;
				mismatch_s_first_hit = 1; // Signal first hit for S
			end
				stats1.errors_s = stats1.errors_s + 1'b1;
			end
			
			// Check 'overflow' mismatch
			if (overflow_ref !== overflow_dut) begin
				if (stats1.errors_overflow == 0) begin
				stats1.errortime_overflow = $time;
				mismatch_overflow_first_hit = 1; // Signal first hit for Overflow
			end
				stats1.errors_overflow = stats1.errors_overflow + 1'b1;
			end
			
			// Display details ONLY when the FIRST error of that type is detected
			if (mismatch_s_first_hit && stats1.errors_s == 1) begin
				display_mismatch_details(1, $time);
				mismatch_s_first_hit = 0; // Reset flag
			end
			if (mismatch_overflow_first_hit && stats1.errors_overflow == 1) begin
				display_mismatch_details(2, $time);
				mismatch_overflow_first_hit = 0; // Reset flag
			end
			end

		// add timeout after 100K cycles
		initial begin
			#1000000
			$display("TIMEOUT");
			$finish();
		end

endmodule