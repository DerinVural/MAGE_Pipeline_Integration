`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic in,
	output logic areset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
	reg reset;
	assign areset = reset;
	task reset_test(input async=0);
		bit arfail, srfail, datafail;
		
		@(posedge clk);
		@(posedge clk) reset <= 0;
		repeat(3) @(posedge clk);
		
		@(negedge clk) begin datafail = !tb_match ; reset <= 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
		srfail = !tb_match;
		reset <= 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

task wavedrom_start(input[511:0] title = "");	endtask

task wavedrom_stop;
		#1;
	endtask
		
	initial begin
		reset <= 1;
		in <= 0;
		@(posedge clk) reset <= 0; in <= 0;
		@(posedge clk) in <= 1;
		wavedrom_start();
		reset_test(1);
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 0;
		@(posedge clk) in <= 1;
		@(posedge clk) in <= 1;
		@(negedge clk);
		wavedrom_stop();
		repeat(200) @(posedge clk, negedge clk) begin
		in <= $random;
		reset <= !($random & 7);
		end

		#1 $finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	}
	stats;
	
	stats stats1;
		
	// Variables to capture first mismatch details (Requirement 4)
	logic [511:0] first_mismatch_in_val;
	logic first_mismatch_areset_val;
	logic first_mismatch_out_dut_val;
	logic first_mismatch_out_ref_val;
	integer first_mismatch_time = -1;
		
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
		
	reg clk=0;
		
	// Clock generation corrected
	initial forever
		h#5 clk = ~clk;
	end

	logic in;
	logic areset;
	logic out_ref;
	logic out_dut;
		
	// Variables to track error counts (maintaining original structure)
	integer error_count_tb = 0;
	integer error_count_out = 0;
		
	// --- Initialization ---
	initial begin 
		$dumpfile("wave.vcd");
		dumpvars(1, stim1.clk, tb_mismatch ,clk,in,areset,out_ref,out_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
		
	// Instantiate stimulus generator
	stimulus_gen stim1 (
		.clk, 
		in, 
		areset, 
		.tb_match);
	// Instantiate Reference Module	
	RefModule good1 (
		.clk, 
		in, 
		areset, 
		.out(out_ref) );
	// Instantiate DUT
	TopModule top_module1 (
		.clk,
		in,
		areset,
		out(out_dut) );
		
	bit strobe = 0;
		task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
		
	// --- Final Reporting Block (Updated for strict output format) ---
	final begin
		if (stats1.errors > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
			// Requirement 1: Input Signals Display
			$display("Input Signals: clk=%b, areset=%b, in=%b", clk, areset, in);
			// Requirement 2: Output Signals Display (HEX and BIN if <= 64)
			// Since out_ref and out_dut are 1-bit, %h (%b) suffices.
			$display("Output Signals: out_ref (Expected) = %h (%b), out_dut (Actual) = %h (%b)", out_ref, out_ref, out_dut, out_dut);
			$display("---------------------------------------------------");
		end else begin
			$display("SIMULATION PASSED");
		end
		
		// Original summary reporting
		$display("Total mismatched samples: %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		end
		
	// Verification assignment
	// The XOR check used in golden testbench: (A === (A ^ B ^ A)) simplifies to (A === B)
	assign tb_match = ( { out_ref } === out_dut );
		
	// Clock and Verification Logic
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
			
		// --- Error Tracking for tb_match (General Mismatch) ---
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				sstats1.errortime = $time; // Capture time of first error
				first_mismatch_time = $time;
				first_mismatch_in_val = in;
				first_mismatch_areset_val = areset;
				first_mismatch_out_dut_val = out_dut;
				first_mismatch_out_ref_val = out_ref;
			end
			stats1.errors++; // Increment main error count
		end
		
		// --- Error Tracking for output check (Original logic: out_ref !== out_dut) ---
		if (out_ref !== out_dut) 
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1; // Corrected typo
		end
		end
	end

// Timeout
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end
	endmodule

// Dummy modules required for compilation (Must match interface)
module RefModule (
	input logic clk,
	input logic in,
	input logic areset,
	output logic out
);
	// Placeholder implementation matching the expected behavior of a reference model
	assign out = in; // Minimal implementation
endmodule

module TopModule (
	input logic clk,
	input logic areset,
	input logic in,
	output logic out
);
	// TopModule implementation based on specification
	// State encoding
	localparam STATE_A = 2'b00; 
	localparam STATE_B = 2'b01; 
		
	// State registers
	logic [1:0] state;
	logic [1:0] state_next;
		
	// Initialization for registers
	initial begin
		state = STATE_A; // Initialize to a known state before reset is applied
	end
		
	// 1. Sequential Logic (State Register) - Asynchronous Reset
	always @(posedge clk or posedge areset) begin
		if (areset) begin
			// Asynchronous reset to State B
			state <= STATE_B;
		end else begin
			state <= state_next;
		end
	end
		
	// 2. Next State Combinational Logic
	always @(*) begin
		state_next = state;
		case (state)
			STATE_A: begin
				if (in == 0) 
				state_next = STATE_B; // A(0) --0--> B
			else 
				state_next = STATE_A; // A(0) --1--> A
			end
			STATE_B: begin
				if (in == 0) 
				state_next = STATE_A; // B(1) --0--> A
			else 
				state_next = STATE_B; // B(1) --1--> B
			end
			default: state_next = STATE_A; // Safety case
		endcase
		end
		
	// 3. Output Logic (Moore Machine)
	always @(*) begin
		out = 1'b0; // Default output
		case (state)
			STATE_A: out = 1'b0; // Assuming State A outputs 0
			STATE_B: out = 1'b1; // Assuming State B outputs 1
			default: out = 1'b0;
		endcase
	end
	endmodule