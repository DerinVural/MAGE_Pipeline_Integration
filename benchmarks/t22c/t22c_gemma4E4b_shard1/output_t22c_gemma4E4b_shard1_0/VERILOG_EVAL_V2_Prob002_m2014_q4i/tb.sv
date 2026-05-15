`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			
		end
		
		#1 $finish;
	end
endmodule

// Assuming RefModule exists and matches the interface required by the golden testbench
module RefModule (
	output logic out
);
	assign out = 1'b1; // Placeholder logic matching the expected constant drive of TopModule if it were perfect
endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Signals from golden testbench
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	// Correct clock generation
	always #5 clk = ~clk;

	logic out_ref;
	logic out_dut;

	// Variables to store state at first mismatch
	logic first_mismatch_detected;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,out_ref,out_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate modules as per golden testbench
	stimulus_gen stim1 (
		.clk, 
		.*  );
	RefModule good1 (
		.out(out_ref) );
	
	TopModule top_module1 (
		.out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Monitor and Error Counting Logic
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Output Mismatch Tracking (Retaining original complex logic)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
		end
		
		// --- DETAILED MISMATCH DISPLAY LOGIC (Triggered on first overall mismatch) ---
		if (!tb_match && stats1.errors == 1 && !first_mismatch_detected) begin
			$display(
			"===================================================",
			"*** FIRST MISMATCH DETECTED AT TIME %0d ps ***", $time,
			"==================================================="
			);
			// Inputs (stimulus_gen.clk): Note: clk is registered, showing its value at the clock edge.
			$display("Inputs (stimulus_gen.clk): %b", clk);
			// Reference Output (out_ref):
			$display("Reference Output (out_ref): HEX=%h, BIN=%b", out_ref, out_ref);
			// DUT Output (out_dut):
			$display("DUT Output (out_dut):     HEX=%h, BIN=%b", out_dut, out_dut);
			// Expected Output (out_ref):
			$display("Expected Output (out_ref): HEX=%h, BIN=%b", out_ref, out_ref);
			end
		
		// Set flag to avoid repeated detailed display
		first_mismatch_detected = 1;
	end

	end

	// Add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
	
	// Final Simulation Status Check
	initial begin
		// Wait a bit longer than the last clock edge to ensure monitoring is complete
		@(negedge clk);
		#1;
		
		if (stats1.errors == 0) begin
			$display(
			"===================================================",
			"SIMULATION PASSED",
			"==================================================="
			);
			end
		else begin
			$display(
			"===================================================",
			"SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime,
			"==================================================="
			);
			end
		$finish();
	end

endmodule