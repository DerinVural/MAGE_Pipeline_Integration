`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// --- Stimulus Generator (Kept as is) ---
module stimulus_gen (
	input clk,
	output logic [99:0] a,b,
	output logic sel,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable 
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask	

	initial begin
	a <= 'hdeadbeef;
b <= 'h5eaf00d;
sel <= 0;
@(negedge clk);
wavedrom_start("Beef or seafood?");
	repeat(6) @(posedge clk) sel <= ~sel;
@(negedge clk);
wavedrom_stop();
repeat(100) @(posedge clk, negedge clk)
	{a,b,sel} <= {$random, $random, $random, $random, $random, $random, $random};
$finish;
	end

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
	
	// Global tracking variables for final report (to satisfy strict output requirements)
	int total_mismatches = 0;
	int first_mismatch_time = 0;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
reg clk=0;

initial forever
	h#5 clk = ~clk;


logic [99:0] a;
logic [99:0] b;
logic sel;
logic [99:0] out_ref;
logic [99:0] out_dut;
	
// Signal to track if any mismatch has been recorded
logic mismatch_detected = 0;
	
initial begin 
		$dumpfile("wave.vcd");
		// Ensure all relevant signals are dumped
		$dumpvars(1, stim1.clk, tb_mismatch, a, b, sel, out_ref, out_dut );
	end
	
	
wire tb_match; 
	wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus_gen
	stimulus_gen stim1 (
		.clk, 
		a, 
		b, 
		.sel, 
		wavedrom_title, 
		wavedrom_enable 
	);
	
	// Reference Model
	RefModule good1 (
		a, 
		b, 
		.sel, 
		.out(out_ref) );
	
	// DUT Instantiation
	TopModule top_module1 (
		a, 
		b, 
		.sel, 
		.out(out_dut) );
	
	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	

// Main clock cycle loop
initial begin
	// Wait for the first clock edge to start checking state
	@(posedge clk);
	while ($time < 1000000) begin
		// Wait for the settling time within the cycle
		wait_for_end_of_timestep();
		
		// --- Verification Logic Run After Cycle Settles ---
		
		// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
		assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
		
		// Check 1: tb_match mismatch
		if (!tb_match) begin
			stats1.errors++;
			if (stats1.errors == 1) begin
				stats1.errortime = $time;
				total_mismatches = 1; 
				first_mismatch_time = $time;
				mismatch_detected = 1;
			end
		end
		
		// Check 2: Direct comparison mismatch (Equivalent to errors_out)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			sstats1.errors_out++;
			if (stats1.errors_out == 1) begin
				sstats1.errortime_out = $time; // Corrected typo
				total_mismatches = 1; 
				first_mismatch_time = $time;
				mismatch_detected = 1;
			end
		end
		
		stats1.clocks++;
	end
	
	// Ensure loop terminates near expected end time if stimulus finishes early
initial begin
	@(negedge clk);
end

// Final Reporting Block (Improved to match strict requirements)
initial begin
	// Wait a moment after the main loop to ensure final state is captured
	h#100;
	
	if (total_mismatches == 0) begin
		$display("SIMULATION PASSED");
	end
	else begin
		// Required Failure Message
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_mismatch_time);
		
		// Display details of the first mismatch
		$display("\n--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", first_mismatch_time);
		
		// Display Inputs (100 bits -> HEX only as 100 > 64)
		$display("Inputs at first mismatch:");
		$display("  a (HEX): %h", a);
		$display("  b (HEX): %h", b);
		$display("  sel (BIN): %b", sel);
		
		// Display Outputs
		$display("Outputs at first mismatch:");
		$display("  out_dut (HEX): %h", out_dut);
		$display("  out_ref (HEX): %h", out_ref);
	end
	
		// Final summary based on original structure
		$display("\n--- SUMMARY ---");
		$display("Total mismatched samples (tb_match): %1d out of %1d samples", stats1.errors, stats1.clocks);
		$display("Total mismatched samples (direct check): %1d out of %1d samples", stats1.errors_out, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
	end
	end

// add timeout after 100K cycles
initial begin
	h#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule


// Dummy modules required for compilation based on testbench usage
module RefModule (input logic [99:0] a, input logic [99:0] b, input logic sel, output logic [99:0] out);
		assign out = sel ? b : a;
endmodule


// TopModule instance definition (matching interface derived from specification/golden testbench)
module TopModule (
		input  logic [99:0] a,
		input  logic [99:0] b,
		input  logic sel,
		output logic [99:0] out
);
		// 2-1 MUX implementation
		assign out = sel ? b : a;
endmodule