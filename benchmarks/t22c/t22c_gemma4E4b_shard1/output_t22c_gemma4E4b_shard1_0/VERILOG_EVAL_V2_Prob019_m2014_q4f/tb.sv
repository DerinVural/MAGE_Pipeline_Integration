`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (As per golden testbench) ---
module stimulus_gen (
	input clk,
	output logic in1, in2
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{in1, in2} <= $random;
		end
		
		#1 $finish;
	end
	endmodule

// --- Reference Module (Assumed based on golden testbench usage) ---
module RefModule (
    input in1,
    input in2,
    output out
);
    // Reference logic must match DUT logic: out = in1 & (~in2)
    assign out = in1 & (~in2);
endmodule

// --- DUT (TopModule) Implementation ---
module TopModule (
    input in1,
    input in2,
    output out
);
    // Logic: Two inputs (in1 and in2) go to an AND gate, but the in2 input to the AND gate has a bubble.
    // Bubble on in2 means the signal driving the AND gate is inverted: ~in2
    assign out = in1 & (~in2);
endmodule

// --- Testbench ---
module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	// State variables for capturing the first mismatch details
	logic capture_mismatch = 1'b0;
	int first_mismatch_time = 0;
	logic first_mismatch_in1 = 0;
	logic first_mismatch_in2 = 0;
	logic first_mismatch_out_dut = 0;
	logic first_mismatch_out_ref = 0;
	
	// Waveform dumping setup (As per golden testbench)
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	
	// Clock generation
	initial forever
		#5 clk = ~clk;

	// Signals
	logic in1;
	logic in2;
	logic out_ref;
	logic out_dut;

	// Control signals
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Wave dumping setup
	initial begin 
		$dumpfile("wave.vcd");
		// Note: The golden testbench references 'tb_mismatch' and 'top_module1' which is fine, but we ensure all necessary signals are dumped.
		$dumpvars(1, tb, in1, in2, out_ref, out_dut, tb_mismatch);
	end

	// Stimulus generation
	stimulus_gen stim1 (
		.clk,
		.* 
		.in1,
		.in2 
	);
	
	// Reference Model Instantiation
	RefModule good1 (
		.in1,
		.in2,
		.out(out_ref) 
	);
	
	// DUT Instantiation
	TopModule top_module1 (
		.in1,
		.in2,
		.out(out_dut) 
	);

	
	// Task to delay until the end of the time step (As per golden testbench)
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task

	// Verification logic (Matches golden testbench) 
	// (A ^ B ^ A) == B, so this verifies out_ref === out_dut
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

	// Main Simulation Loop and Verification
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;

		// 1. Track Mismatches (tb_match)
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture state for the first mismatch
				capture_mismatch = 1'b1;
				first_mismatch_time = $time;
				first_mismatch_in1 = in1;
				first_mismatch_in2 = in2;
				out_dut = out_dut;
				out_ref = out_ref;
				// Expected output is out_ref
				// Note: The original testbench only checked errors_out, but we track the first failure here.
			end
			s
		stats1.errors++;
		end

		// 2. Track Errors_out (Matching original logic)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; 
		end
		end

	end

   // Timeout mechanism (As per golden testbench)
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

   // Final Reporting Logic (IMPROVED)
   initial begin
     @(negedge clk);
     #1; // Wait for one stable cycle after stimulus generator might finish

     if (stats1.errors == 0) begin
         $display("\n========================================");
         $display("SIMULATION PASSED");
         $display("========================================");
     end else begin
         $display("\n========================================");
         $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_mismatch_time);

         // Display detailed state at the first mismatch time
         $display("\n--- DETAILS AT FIRST MISMATCH (Time: %0d ps) ---", first_mismatch_time);
         
         // Input Signals
         $display("Inputs: in1 = %b (HEX: %h), in2 = %b (HEX: %h)", first_mismatch_in1, first_mismatch_in1, first_mismatch_in2, first_mismatch_in2);
         
         // Output Signals
         $display("Outputs: DUT out = %b (HEX: %h), Reference out = %b (HEX: %h)", 
                 first_mismatch_out_dut, first_mismatch_out_dut, first_mismatch_out_ref, first_mismatch_out_ref);
         
         // Expected Output (The reference model output)
         $display("Expected Output (Reference): %b (HEX: %h)", first_mismatch_out_ref, first_mismatch_out_ref);
		end

     // Display summary based on original logic
     $display("\n--- SUMMARY ---");
     $display("Total mismatched samples (tb_match): %1d out of %1d samples", stats1.errors, stats1.clocks);
     $display("Total mismatched samples (errors_out): %1d out of %1d samples", stats1.errors_out, stats1.clocks);
     $display("Simulation finished at %0d ps", $time);
	end

endmodule