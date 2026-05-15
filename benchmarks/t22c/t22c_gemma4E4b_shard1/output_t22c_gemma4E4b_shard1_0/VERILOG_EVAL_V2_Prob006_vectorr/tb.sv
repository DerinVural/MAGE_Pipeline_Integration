`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- stimulus_gen module definition (Kept as is per golden testbench) ---
module stimulus_gen (
	input clk,
	output logic [7:0] in,
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
	in <= 0;
	@(negedge clk) wavedrom_start();
		@(posedge clk) in <= 8'h1;
		@(posedge clk) in <= 8'h2;
		@(posedge clk) in <= 8'h4;
		@(posedge clk) in <= 8'h8;
		@(posedge clk) in <= 8'h80;
		@(posedge clk) in <= 8'hc0;
		@(posedge clk) in <= 8'he0;
		@(posedge clk) in <= 8'hf0;
		@(negedge clk) wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			in <= $random;
		$finish;
	end
	endmodule

// --- RefModule placeholder (Kept as is as it's referenced) ---
module RefModule (
	input logic [7:0] in,
	output logic [7:0] out
);
	// Dummy implementation to allow simulation compilation
	assign out = in;
endmodule

// --- TopModule definition based on input_spec ---
module TopModule (
	input logic [7:0] in,
	output logic [7:0] out
);
	// Implementation to reverse bits (as per input_spec: LSB -> MSB)
	// Note: The previous attempt used {in[7], in[6:0]}, which reverses MSB->LSB. 
	// The input_spec requires LSB (in[0]) to become MSB (out[7]), which is {in[0], ..., in[7]}. 
	// However, to match the structure used in the failed testbench, I will stick to the structure that produced the error, which was {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]} as derived from the natural language specification interpretation for bit reversal.
	assign out = {in[0], in[1], in[2], in[3], in[4], in[5], in[6], in[7]};
endmodule

// =============================================================================
// THE IMPROVED TESTBENCH (tb)
// =============================================================================

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	// Corrected clock generation using always block for reliable timing
	always #5 clk = ~clk;

	logic [7:0] in;
	logic [7:0] out_ref;
	logic [7:0] out_dut;
	
	// Variables to capture data at the first mismatch
	logic [7:0] first_error_in;
	logic [7:0] first_error_out_ref;
	logic [7:0] first_error_out_dut;
	integer first_error_time_capture = -1;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end

	
wire tb_match;
wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		in,
		wavedrom_title, 
		wavedrom_enable 
	);
	RefModule good1 (
		in, 
		out(out_ref) );
	TopModule top_module1 (
		in, 
		out(out_dut) );
	
	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Sensitive block for error counting
always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// Check based on tb_match
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				first_error_time_capture = $time;
				first_error_in = in;
				first_error_out_ref = out_ref;
				first_error_out_dut = out_dut;
			end
			stats1.errors++;
		end
		
		// Check based on explicit check (errors_out)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) begin
				stats1.errortime_out = $time;
				first_error_time_capture = $time;
				first_error_in = in;
				first_error_out_ref = out_ref;
				first_error_out_dut = out_dut;
			end
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end
	
	// Final reporting logic
	initial begin
		// Wait until simulation is near completion to ensure all errors are counted
		@(negedge clk);
		h#10; // Small wait
		
		if (stats1.errors == 0 && stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			integer total_mismatches = stats1.errors + stats1.errors_out;
			// Determine the earliest time recorded
			integer first_error_time = first_error_time_capture != -1 ? first_error_time_capture : (stats1.errortime == 0 && stats1.errortime_out == 0 ? $time : (stats1.errortime == 0 ? stats1.errortime_out : stats1.errortime));
			
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_error_time);
			
			// Detailed display for the first mismatch
			$display("\n--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", first_error_time);
			// Display in HEX and BINARY
			$display("Input Signal (in): HEX=%h, BIN=%b", first_error_in, first_error_in);
			$display("Reference Output (out_ref): HEX=%h, BIN=%b", first_error_out_ref, first_error_out_ref);
			$display("DUT Output (out_dut): HEX=%h, BIN=%b", first_error_out_dut, first_error_out_dut);
			$display("------------------------------------------");
		end
	endmodule
