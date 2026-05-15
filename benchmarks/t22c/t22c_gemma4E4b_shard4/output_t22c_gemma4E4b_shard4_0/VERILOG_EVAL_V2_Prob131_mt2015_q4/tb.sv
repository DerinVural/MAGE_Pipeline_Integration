 `timescale 1 ps/1 ps
 `define OK 12
 `define INCORRECT 13
 
 // Assuming RefModule and TopModule exist externally as per the golden testbench
 
 module stimulus_gen (
 	input logic clk,
 	output logic x,
 	output logic y
 );
 	
 	always @(posedge clk, negedge clk)
 		{x, y} <= $random % 4;
 	
 	initial begin
 		repeat(100) @(negedge clk);
 		#1 $finish;
 	end
 	endmodule
 
 module tb();
 	
 	// Structure definition
 	typedef struct packed {
 		int errors;
 		int errortime;
 		int errors_z;
 		int errortime_z;
 		int clocks;
 	} stats;
 	
 	stats stats1;
 	
 	
 	wire[511:0] wavedrom_title;
 	wire wavedrom_enable;
 	int wavedrom_hide_after_time;
 	
 	reg clk=0;
 	initial forever
 		#5 clk = ~clk;
 	end
 	
 	logic x;
 	logic y;
 	logic z_ref;
 	logic z_dut;
 	
 	// --- Signal Display Utility Task ---
 	// Implements display logic for required format (HEX/BIN)
 	task display_signals(string msg);
 		$display("==================================================================");
 		$display("%s at Time: %0t ps", msg, $time);
 		$display("------------------------------------------------------------------");
 		// Inputs: x, y
 		$display("Inputs: x = %b (0x%h), y = %b (0x%h)", x, x, y, y);
 		// Outputs: z_ref, z_dut
 		$display("Outputs: z_ref = %b (0x%h), z_dut = %b (0x%h)", z_ref, z_ref, z_dut, z_dut);
 		$display("Expected Z (Based on Ref): %b", z_ref);
 		$display("==================================================================");
 	endtask
 	
 	// --- Initialization and Dumping ---
 	initial begin 
 		$dumpfile("wave.vcd");
 		// tb_mismatch must be declared before this line to be valid for $dumpvars
 		$dumpvars(1, stim1.clk, tb_mismatch ,x,y,z_ref,z_dut );
 	end
 	
 	wire tb_match;
 	wire tb_mismatch = ~tb_match;
 	
 	stimulus_gen stim1 (
 		.clk,
 		.* , 
 		.x,
 		.y );
 	
 	// Assuming RefModule exists and matches interface
 	RefModule good1 (
 		.x,
 		.y,
 		z(z_ref) );
 	
 	// Assuming TopModule exists and matches interface
 	TopModule top_module1 (
 		.x,
 		.y,
 		z(z_dut) );
 	
 	
 	bit strobe = 0;
 	
 	task wait_for_end_of_timestep;
 		repeat(5) begin
 			strobe <= !strobe;  // Try to delay until the very end of the time step.
 			@(strobe);
 		end
 	endtask
 	
 	// --- Clock and Verification Logic ---
 	always @(posedge clk, negedge clk) begin
 		
 		stats1.clocks++;
 		
 		// Check for DUT Mismatch (tb_match) - Required detailed display on first error
 		if (!tb_match) begin
 			if (stats1.errors == 0) begin 
 				stats1.errortime = $time;
 				// Trigger detailed display upon first error
 				display_signals("FIRST DUT MISMATCH DETECTED");
 			end
 			stats1.errors++;
 		end
 		
 		// Check for Z Reference Mismatch (z_ref vs z_dut) - Preserving original logic
 		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
 		begin 
 			if (stats1.errors_z == 0) stats1.errortime_z = $time;
 			stats1.errors_z = stats1.errors_z+1'b1; 
 		end
 	end
 	
 	// Verification assignment (Original logic preserved)
 	assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
 	
 	// --- Final Results Display ---
 	initial begin
 		@(negedge clk);
 		// Wait a moment to ensure final state is captured
 		#10;
 		
 		// Original Hint Display (Kept for backward compatibility with golden testbench output)
 		if (stats1.errors_z) 
 			$display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
 		else 
 			$display("Hint: Output 'z' has no mismatches.");
 		
 		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
 		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
 		
 		// REQUIRED FINAL DISPLAY LOGIC
 		if (stats1.errors > 0) begin
 			s$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
 		end else begin
 			s$display("SIMULATION PASSED");
 		end
 	end
 	
 	// add timeout after 100K cycles
 	initial begin
 		#1000000
 		$display("TIMEOUT");
 		$finish();
 	end
 
 endmodule