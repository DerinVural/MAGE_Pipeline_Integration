`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// *******************************************************
// Stimulus Generator (Kept as per golden testbench)
// *******************************************************
module stimulus_gen (
	input clk,
	output reg [7:0] d,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
task wavedrom_stop;
		h#1;
	endtask
	
	always @(posedge clk, negedge clk)
		d <= $random % 256;
	
	initial begin
		@(posedge clk);
		wavedrom_start("Positive-edge triggered DFF");
		repeat(10) @(posedge clk);
		wavedrom_stop();
		h#100;
		$finish;
	end
	endmodule


// *******************************************************
// DUT (TopModule) Implementation (Required for simulation)
// *******************************************************
module TopModule (
	input logic clk,
	input logic [7:0] d,
	output logic [7:0] q
);
	// 8 D flip-flops triggered by positive edge of clock
	always @(posedge clk)
	begin
		q <= d;
	end
endmodule


// *******************************************************
// Reference Module (Mocked as per golden testbench structure)
// *******************************************************
module RefModule (
	input logic clk,
	input logic [7:0] d,
	output logic [7:0] q
);
	// Assuming RefModule behaves identically to TopModule for golden comparison
	always @(posedge clk)
	begin
		q <= d;
	end
endmodule


// *******************************************************
// Testbench (Improved and Finalized) 
// *******************************************************
module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
		
		// For detailed first mismatch logging
		int first_mismatch_time;
		logic [7:0] first_mismatch_d;
		logic [7:0] first_mismatch_q_dut;
		logic [7:0] first_mismatch_q_ref;
	}
	stats;
	
	stats stats1;
	
	// Helper task for formatted printing
	task print_signal_value(string signal_name, logic [7:0] value);
	begin
		$display("  %s: HEX = %h, BIN = %b", signal_name, value, value);
	end
	endtask
	
	// Helper task to display signals upon first mismatch
	task display_mismatch_details(string reason);
	begin
		$display("======================================================