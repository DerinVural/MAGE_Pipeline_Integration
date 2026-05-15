`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Keeping stimulus_gen as provided in the golden testbench
module stimulus_gen (
	input clk,
	output logic in,
	output logic reset
);
	initial begin
		reset <= 1;
		in <= 1;
		@(posedge clk);
		reset <= 0;
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(10) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(10) @(posedge clk);
		in <= 1;
		@(posedge clk);
		in <= 0;
		repeat(9) @(posedge clk);
		in <= 1;
		@(posedge clk);
		
		repeat(800) @(posedge clk, negedge clk) begin
		in <= $random;
		reset <= !($random & 31);
		end
		#1 $finish;
	end
	endmodule

// RefModule (Golden Reference Model) - Placeholder/Assumed to exist as in golden testbench
module RefModule (
	input clk,
	input in,
	input reset,
	output logic [7:0] out_byte,
	output logic done
);
	// Assume implementation for golden reference
endmodule

// TopModule (Device Under Test - DUT)
module TopModule (
	input  logic clk,
	input  logic in,
	input  logic reset,
	output logic [7:0] out_byte,
	output logic done
);
// DUT implementation is assumed to be present or synthesized correctly
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_byte;
		int errortime_out_byte;
		int errors_done;
		int errortime_done;
		
		int clocks;
		logic [7:0] first_mismatch_in_byte;
		logic [7:0] first_mismatch_out_byte;
		logic first_mismatch_done;
		int first_mismatch_time;
	} stats;
	
	stats stats1;
	
	// Captured signals for detailed reporting
	logic [7:0] capture_in_byte;
	logic capture_clk;
	logic capture_reset;
	logic [7:0] capture_out_byte_ref;
	logic capture_done_ref;
	logic [7:0] capture_out_byte_dut;
	logic capture_done_dut;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic in;
	logic reset;
	logic [7:0] out_byte_ref;
	logic [7:0] out_byte_dut;
	logic done_ref;
	logic done_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_byte_ref,out_byte_dut,done_ref,done_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		in, 
		.reset );
	RefModule good1 (
		.clk, 
		in, 
		.reset,
		out_byte(out_byte_ref),
		done(done_ref) );
	
	TopModule top_module1 (
		.clk,
		in,
		.reset,
		out_byte(out_byte_dut),
		done(done_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask

	
	// Capture signals on every clock edge for logging purposes
	always @(posedge clk, negedge clk) begin
		// Capture inputs
		capture_in_byte <= in;
		capture_clk <= clk;
		capture_reset <= reset;
		// Capture expected outputs
		capture_out_byte_ref <= out_byte_ref;
		capture_done_ref <= done_ref;
		// Capture DUT outputs
		capture_out_byte_dut <= out_byte_dut;
		capture_done_dut <= done_dut;
		
		stats1.clocks++;
		
		// Check overall match
		// XOR check: A === B iff A ^ B ^ A === A
		assign tb_match = ( { out_byte_ref, done_ref } === ( { out_byte_ref, done_ref } ^ { out_byte_dut, done_dut } ^ { out_byte_ref, done_ref } ) );
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				stats1.first_mismatch_time = $time;
				// Capture all relevant state at the first error time
				sstats1.first_mismatch_in_byte = capture_in_byte;
				sstats1.first_mismatch_out_byte = capture_out_byte_ref;
				sstats1.first_mismatch_done = capture_done_ref;
				
				// Tracking specific errors separately (maintaining original logic)
				// Byte Mismatch Check
			if (out_byte_ref !== ( out_byte_ref ^ out_byte_dut ^ out_byte_ref ))
				begin
					if (stats1.errors_out_byte == 0) stats1.errortime_out_byte = $time;
					sstats1.first_mismatch_out_byte = capture_out_byte_ref;
					sstats1.errors_out_byte = stats1.errors_out_byte+1'b1;
				end
				
				// Done Mismatch Check
			if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
				begin
					if (stats1.errors_done == 0) stats1.errortime_done = $time;
					sstats1.first_mismatch_done = capture_done_ref;
					sstats1.errors_done = stats1.errors_done+1'b1;
				end
				
				stats1.errors++;
			end
		end
		end

	// --- Display Functions ---
	task display_signal(input string name, input logic val, input int width);
	begin
		if (width <= 64)
			s$write("%-20s: %h (%b)\n", name, val, val);
		else
			s$write("%-20s: %h\n", name, val);
	end
	task display_signal_byte(input string name, input logic [7:0] val);
	begin
		s$write("%-20s: %h (%b)\n", name, val, val);
	endtask
	task display_state_at_mismatch;
	begin
		$display("====================================================================");
		$display("!!! FIRST MISMATCH DETECTED AT TIME %0d ps !!!", stats1.first_mismatch_time);
		$display("-------------------- INPUTS ---------------------");
		display_signal("clk", capture_clk, 1);
		display_signal("in", capture_in_byte, 1);
		display_signal("reset", capture_reset, 1);
		$display("-------------------- OUTPUTS (EXPECTED) ---------------");
		display_signal_byte("out_byte_ref", capture_out_byte_ref);
		display_signal("done_ref", capture_done_ref, 1);
		$display("-------------------- OUTPUTS (DUT) ---------------");
		display_signal_byte("out_byte_dut", capture_out_byte_dut);
		display_signal("done_dut", capture_done_dut, 1);
		$display("====================================================================");
	endtask

	// Final block replacement to meet strict requirements
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.first_mismatch_time);
			display_state_at_mismatch();
		end
	end
	
	// add timeout after 100K cycles
	initial begin
		#1000000
		if ($time > 0) begin // Check if simulation hasn't already finished
			$display("TIMEOUT");
			$finish();
		end
	end

endmodule