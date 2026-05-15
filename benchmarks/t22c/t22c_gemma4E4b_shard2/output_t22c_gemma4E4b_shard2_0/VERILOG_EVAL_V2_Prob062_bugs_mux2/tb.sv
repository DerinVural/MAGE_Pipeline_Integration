`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (Copied from Golden Testbench) ---
module stimulus_gen (
	input clk,
	output logic sel,
	output logic [7:0] a,
	output logic [7:0] b,
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
		{a, b, sel} <= '0;
		@(negedge clk) wavedrom_start("");
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
		@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
		
		@(posedge clk, negedge clk) {a, b} <= {8'hff, 8'h00}; sel <= 1'b0;
		@(posedge clk, negedge clk) sel <= 1'b0;
		@(posedge clk, negedge clk) sel <= 1'b1;
		@(posedge clk, negedge clk) sel <= 1'b0;
		@(posedge clk, negedge clk) sel <= 1'b1;
		@(posedge clk, negedge clk) sel <= 1'b1;
		wavedrom_stop();
		
		repeat(100) @(posedge clk, negedge clk)
			{a,b,sel} <= $urandom;
		$finish;
	end
	endmodule

// --- DUT (Fixed Version) ---
module TopModule (
    input  logic sel,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic out
);
	// The logic is standard and correct for a 2-to-1 MUX.
	assign out = (~sel & a) | (sel & b);
endmodule

// --- Testbench ---
module tb();

	// Helper function to display multi-bit values in HEX and BINARY
	function void display_signal(string name, logic value, int width);
	begin
		$display("%s: %h (%b)", name, value, value);
	endfunction
	endfunction
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	
	// Interface signals matching stimulus_gen output/tb input
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	// Clocking
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	// DUT inputs/outputs
	logic sel;
	logic [7:0] a;
	logic [7:0] b;
	logic [7:0] out_ref; // Expected output
	logic [7:0] out_dut; // DUT output

	// State tracking for first mismatch
	int first_mismatch_time = -1;
	
	initial begin 
		$dumpfile("wave.vcd");
		// Note: tb_mismatch signal is defined later, ensuring it's available for dumping
		$dumpvars(1, stim1.clk, tb_mismatch, sel, a, b, out_ref, out_dut );
	end

	// Verification signals
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate Stimulus Generator
	stimulus_gen stim1 (
		.clk, 
		.sel, 
		a, 
		b, 
		wavedrom_title, 
		wavedrom_enable
	);
	
	// Instantiate Reference Module (Good) - Assuming RefModule is available/defined elsewhere
	// Following golden testbench structure, even if RefModule definition is omitted.
	RefModule good1 (
		.sel, 
		a, 
		b, 
		out(out_ref) );
	
	// Instantiate DUT
	TopModule top_module1 (
		.sel, 
		a, 
		b, 
		out(out_dut) );
	
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	

	// Verification Logic
	assign tb_match = ( out_ref === out_dut );
	
	// Main Clock/Error Counting Logic
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// 1. Check Mismatch (General Testbench Mismatch)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			
			// 2. Capture First Mismatch Details
			if (stats1.errors == 1) begin
				first_mismatch_time = $time;
				$display("\n============================================================") ;
				$display("*** FIRST MISMATCH DETECTED ***") ;
				$display("Time: %0d ps", $time);
				$display("------------------------------------------------------------") ;
				$display("Input Signals:") ;
				display_signal("sel", sel, 1);
				display_signal("a", a, 8);
				display_signal("b", b, 8);
				$display("Output Signals:") ;
				display_signal("DUT Output (out_dut)", out_dut, 8);
				display_signal("Expected Output (out_ref)", out_ref, 8);
				$display("============================================================\n") ;
			end
		end
		
		// 3. Original Error Count for 'out' signal (Maintained for compliance)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
	end

   // add timeout after 100K cycles	initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

	// Final Check and Reporting
	initial begin
		@(negedge clk);
		wait(1); // Wait a little bit after expected stimulus ends
		
		$display("==========================================================") ;
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED") ;
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime) ;
		end
		$display("==========================================================") ;
		
		// Retaining original detailed summary logic for debugging context
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule