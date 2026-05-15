`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		output logic c, d,
		output reg[511:0] wavedrom_title,
		output reg wavedrom_enable 
);

		task wavedrom_start(input[511:0] title = "");
	endtask
	
		task wavedrom_stop;
			h#1;
	endtask	

		initial begin
			{c, d} <= 0;
			@(negedge clk) wavedrom_start();
				@(posedge clk) {c, d} <= 2'h0;
				@(posedge clk) {c, d} <= 2'h1;
				@(posedge clk) {c, d} <= 2'h2;
				@(posedge clk) {c, d} <= 2'h3;
			@(negedge clk) wavedrom_stop();
			repeat(50) @(posedge clk, negedge clk)
				{c,d} <= $random;
			$finish;
		end
		endmodule

// DUT Implementation (TopModule)
module TopModule (
    input logic c,
    input logic d,
    output logic [3:0] mux_in
);
    // K-map derived logic:
    // F0(00): 0, F0(01): 0, F0(11): 0, F0(10): 1 -> c & ~d
    assign mux_in[0] = c & (~d);
    
    // F1(01): 1, F1(00): 0, F1(11): 0, F1(10): 0 -> ~c & ~d
    assign mux_in[1] = (~c) & (~d);

    // F2(11): 1, F2(00): 0, F2(11): 1, F2(10): 1 -> c | d
    assign mux_in[2] = c | d;

    // F3(10): 1, F3(00): 0, F3(11): 1, F3(10): 1 -> c ^ d
    assign mux_in[3] = c ^ d;

endmodule

// Reference Module (Placeholder, matching golden testbench structure)
module RefModule (
    input c,
    input d,
    output [3:0] mux_in
);
    // Using placeholder as in golden testbench
    assign mux_in = 4'b0000; 
endmodule

// Testbench
module tb();

		typedef struct packed {
			int errors;
			int errortime;
			int errors_mux_in;
			int errortime_mux_in;
			int clocks;
			logic [1:0] first_mismatch_c_d;
			logic [3:0] first_mismatch_ref;
			logic [3:0] first_mismatch_dut;
		}
		stats;
		
		stats stats1;
		stats stats_mux_in;
		
		// Signals from stimulus_gen (must maintain structure)
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		initial forever
			#5 clk = ~clk;
		end

		logic c;
		logic d;
		logic [3:0] mux_in_ref;
		logic [3:0] mux_in_dut;

		// Signals to capture first mismatch data
		logic [1:0] first_mismatch_c_d = 2'bx;
		logic [3:0] first_mismatch_ref = 4'bx;
		logic [3:0] first_mismatch_dut = 4'bx;

		initial begin 
			$dumpfile("wave.vcd");
			$dumpvars(1, tb);
		end

		wire tb_match;
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk, clk,
			.*,
			.c, c,
			.d, d 
		);
		RefModule good1 (
			.c, c,
			.d, d,
			.mux_in(mux_in_ref) 
		);
		TopModule top_module1 (
			.c, c,
			.d, d,
			.mux_in(mux_in_dut) 
		);

		
		bit strobe = 0;
		task wait_for_end_of_timestep;
			repeat(5) begin
				strobe <= !strobe;  // Try to delay until the very end of the time step.
				@(strobe);
			end
		endtask

		// Verification assignment (maintaining original structure)
		assign tb_match = ( { mux_in_ref } === ( { mux_in_ref } ^ { mux_in_dut } ^ { mux_in_ref } ) );
		
		always @(posedge clk, negedge clk) begin
			
			stats1.clocks++;
			
			// General Mismatch Tracking
			if (!tb_match) begin
					if (stats1.errors == 0) stats1.errortime = $time;
				stats1.errors++;
				// Capture data at first mismatch
			if (stats1.errors == 1) begin
					first_mismatch_c_d <= {c, d};
					first_mismatch_ref <= mux_in_ref;
					first_mismatch_dut <= mux_in_dut;
				end
			end
			
			// Specific Mismatch Tracking (using the original, potentially flawed, check)
			if (mux_in_ref !== ( mux_in_ref ^ mux_in_dut ^ mux_in_ref ))
			begin 
				stats_mux_in.clocks++;
				if (stats_mux_in.errors_mux_in == 0) stats_mux_in.errortime_mux_in = $time;
				stats_mux_in.errors_mux_in = stats_mux_in.errors_mux_in+1'b1;
				// Capture data at first mismatch for mux_in
			if (stats_mux_in.errors_mux_in == 1) begin
					first_mismatch_c_d <= {c, d};
					first_mismatch_ref <= mux_in_ref;
					first_mismatch_dut <= mux_in_dut;
			end
			end
		
	end

		// Add timeout after 100K cycles
		initial begin
			#1000000
			$display("TIMEOUT");
			$finish();
		end

		final begin
			$display("\n=======================================================================");
			
			if (stats_mux_in.errors_mux_in > 0) begin
				// Mandated Failure Display
				$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats_mux_in.errors_mux_in, stats_mux_in.errortime_mux_in);
				$display("--- First Mismatch Details ---");
				$display("Time: %0d ps", stats_mux_in.errortime_mux_in);
				// Inputs (c, d) - <= 64 bits, display all three formats
				$display("Inputs (c, d): %0d (Hex: %h, Bin: %b)", first_mismatch_c_d, first_mismatch_c_d, first_mismatch_c_d);
				// Expected Output (mux_in_ref) - <= 64 bits, display all three formats
				$display("Expected Output (mux_in_ref): %0d (Hex: %h, Bin: %b)", first_mismatch_ref, first_mismatch_ref, first_mismatch_ref);
				// Actual Output (mux_in_dut) - <= 64 bits, display all three formats
				$display("Actual Output (mux_in_dut): %0d (Hex: %h, Bin: %b)", first_mismatch_dut, first_mismatch_dut, first_mismatch_dut);
			end else begin
				// Mandated Success Display
				$display("SIMULATION PASSED");
			end
			
			// Keep original general mismatch summary
			$display("Total mismatched samples (general): %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
		end

endmodule