`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// --- Stimulus Generator Module (Copied from Golden Testbench) ---
module stimulus_gen (
	input clk,
	output logic [15:0] in,
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

	always @(posedge clk, negedge clk)
		in <= $random;
	
	initial begin
		wavedrom_start("Random inputs");
		repeat(10) @(posedge clk);
		wavedrom_stop();
		repeat(100) @(negedge clk);
		$finish;
	end
	endmodule


// --- Reference Module (Placeholder/Assumed to exist, kept as is) ---
module RefModule (
    input  logic [15:0] in,
    output logic [7:0] out_hi,
    output logic [7:0] out_lo
);
    // Reference implementation should match TopModule
    assign out_hi = in[15:8];
    assign out_lo = in[7:0];
endmodule


// --- Main Testbench Module ---
module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_hi;
		int errortime_out_hi;
		int errors_out_lo;
		int errortime_out_lo;
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
initial forever
		#5 clk = ~clk; // Clock generation
	

logic [15:0] in;
logic [7:0] out_hi_ref;
logic [7:0] out_hi_dut;
logic [7:0] out_lo_ref;
logic [7:0] out_lo_dut;


// --- Formatting Helper Function ---
// Handles displaying signals in HEX and BIN if width <= 64
task display_signal_formatted(string name, logic value, int width);
		$display("
======================================================");
		$display("--- MISMATCH DETAIL: %s ---", name);
		$display("Time: %0d ps", $time);
		
		string hex_str = $sformatf("%h", value);
		string bin_str = $sformatf("%b", value);
		
		if (width <= 64) begin
			$display("%s: HEX = %s, BIN = %s", name, hex_str, bin_str);
			$display("=======================================================");
			end
		else begin
			$display("%s: HEX = %h", name, value);
			end
		endtask
	

// --- Simulation Setup ---
initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_hi_ref,out_hi_dut,out_lo_ref,out_lo_dut );
end
	
	
wire tb_match;
wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus generator
stimulus_gen stim1 (
		.clk,
		.*,
		in 
);
	// Instantiate reference module
RefModule good1 (
		in,
		out_hi(out_hi_ref),
		out_lo(out_lo_ref) );
	// Instantiate DUT
TopModule top_module1 (
		in,
		out_hi(out_hi_dut),
		out_lo(out_lo_dut) );
	
	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
// Initialize stats
initial begin
		stats1 = '{default: 0};
end
	
	// Verification: Check overall match
assign tb_match = ( { out_hi_ref, out_lo_ref } === { out_hi_dut, out_lo_dut } );
	
	// Check and log errors
always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// 1. Total Mismatch Check
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		
		// Capture state at FIRST total mismatch time for detailed display
		if (stats1.errors == 1) begin
			display_signal_formatted("Input (in)", in, 16);
		display_signal_formatted("Expected Output (Hi/Lo)", {out_hi_ref, out_lo_ref}, 16);
		display_signal_formatted("Actual Output (Hi/Lo)", {out_hi_dut, out_lo_dut}, 16);
		end
	end
	
		// 2. Individual Mismatch Checks (Maintaining original error counting logic)
		if (out_hi_ref !== out_hi_dut) 
		begin 
			if (stats1.errors_out_hi == 0) stats1.errortime_out_hi = $time;
			stats1.errors_out_hi = stats1.errors_out_hi+1'b1; 
		end
		
		if (out_lo_ref !== out_lo_dut) 
		begin 
			if (stats1.errors_out_lo == 0) stats1.errortime_out_lo = $time;
			stats1.errors_out_lo = stats1.errors_out_lo+1'b1; 
		end
	end
	
	// --- Timeout Mechanism ---
initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
end
	
	// --- Final Reporting ---
initial begin
		@(negedge clk);
		#10;
		
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			// Required Failure Format
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", 
			sstats1.errors, stats1.errortime);
		end
		
		// Keep original detailed hints for debugging
		if (stats1.errors_out_hi) $display("Hint: Output 'out_hi' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out_hi, stats1.errortime_out_hi);
		else $display("Hint: Output 'out_hi' has no mismatches.");
		if (stats1.errors_out_lo) $display("Hint: Output 'out_lo' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out_lo, stats1.errortime_out_lo);
		else $display("Hint: Output 'out_lo' has no mismatches.");
		
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end
	endmodule