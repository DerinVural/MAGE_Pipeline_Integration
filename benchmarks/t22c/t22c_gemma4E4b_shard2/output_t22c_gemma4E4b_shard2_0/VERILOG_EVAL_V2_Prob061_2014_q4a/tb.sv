`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generation Module (Kept as is)
module stimulus_gen (
	input clk,
	output logic w, R, E, L
);
	initial begin
		repeat(200) @(posedge clk, negedge clk) begin
			{w,R,E,L} <= $random;
		end
		#1 $finish;
	end
	endmodule

// Reference Module (Assumed to exist for simulation context, kept as is)
module RefModule (
    input  clk,
    input  w,
    input  R,
    input  E,
    input  L,
    output Q
);
    // Placeholder implementation for compilation
    assign Q = 1'b0;
endmodule

// DUT Module (Placeholder for compilation, as we are testing the interface)
module TopModule (
    input  clk,
    input  w,
    input  R,
    input  E,
    input  L,
    output Q
);
    // Placeholder implementation
    assign Q = 1'b0;
endmodule

// Testbench
module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_Q;
		int errortime_Q;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Signals unused in the original TB structure but kept for completeness
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic w;
	logic R;
	logic E;
	logic L;
	logic Q_ref;
	logic Q_dut;

	// Function to display signals nicely (handles 1-bit or wider, adhering to requirement)
	task display_signals(string name, logic [7:0] inputs, logic [7:0] outputs, logic [7:0] expected);
		$display("\n--- Mismatch Detected at Time %0t ps ---", $time);
		$display("--- Inputs (%s) ---", name);
		$display("Inputs: %b (HEX: %h)", inputs, inputs);
		$display("--- Outputs (%s) ---", name);
		$display("DUT Output (Q_dut): %b (HEX: %h)", outputs, outputs);
		$display("Reference Output (Q_ref): %b (HEX: %h)", expected, expected);
		endtask

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,w,R,E,L,Q_ref,Q_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, // Note: stim1 receives clk, but its inputs w, R, E, L are driven internally.
		.*,
		.w, // These connections in the original TB are suspicious (stim1 outputs w, R, E, L but they are connected as inputs to the instantiations). Following original structure.
		.R,
		.E,
		.L
	);
	RefModule good1 (
		.clk,
		w,
		R,
		.E,
		.L,
		.Q(Q_ref) );
	
	TopModule top_module1 (
		.clk,
		w,
		R,
		.E,
		.L,
		.Q(Q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
	
	// Enhanced final block to meet new requirements
	final begin
		if (stats1.errors > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			// Display signals at the first mismatch time
			// Since we cannot easily capture the exact inputs at the time the error counter flips from 0 to 1
			// without further modification to the always block, we report the state at the end of simulation.
			// However, to meet the prompt requirement strictly, the mismatch display logic must be in the always block.
			// We rely on the previous modification in the always block to print detailed info upon FIRST error.
		end
		else begin
			$display("SIMULATION PASSED");
		end
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	// Original verification logic kept:
	assign tb_match = ( { Q_ref } === ( { Q_ref } ^ { Q_dut } ^ { Q_ref } ) );
	
	// Verification logic modified to capture first mismatch details
	always @(posedge clk, negedge clk) begin
		
		// Capture current inputs for potential detailed reporting
		logic [3:0] current_inputs = {w, R, E, L};
		logic [7:0] current_outputs = {Q_dut};
		logic [7:0] current_expected = {Q_ref};

		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Display detailed signals upon first mismatch
			display_signals("Inputs/Outputs", current_inputs, current_outputs, current_expected);
			end
			stats1.errors++;
		end
		
		// Original logic for errors_Q, maintained:
		if (Q_ref !== ( Q_ref ^ Q_dut ^ Q_ref ))
		begin 
			if (stats1.errors_Q == 0) stats1.errortime_Q = $time;
			stats1.errors_Q = stats1.errors_Q+1'b1; 
		end
		
	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule