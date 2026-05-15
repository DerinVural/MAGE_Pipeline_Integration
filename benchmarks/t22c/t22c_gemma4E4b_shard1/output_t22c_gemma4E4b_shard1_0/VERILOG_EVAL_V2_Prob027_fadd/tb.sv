`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic a,b,cin,
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
		wavedrom_start();
		@(posedge clk) {a,b,cin} <= 3'b000;
		@(posedge clk) {a,b,cin} <= 3'b010;
		@(posedge clk) {a,b,cin} <= 3'b100;
		@(posedge clk) {a,b,cin} <= 3'b110;
		@(posedge clk) {a,b,cin} <= 3'b000;
		@(posedge clk) {a,b,cin} <= 3'b001;
		@(posedge clk) {a,b,cin} <= 3'b011;	
		@(negedge clk) wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{a,b,cin} <= $random;
		$finish;
	end

dendmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_cout;
		int errortime_cout;
		int errors_sum;
		int errortime_sum;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Signals derived from stimulus_gen (kept wide as in original TB)
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	// Inputs to DUT (Matching TopModule 1-bit specification)
	logic a;
	logic b;
	logic cin;
	
	// Reference outputs
	logic cout_ref;
	logic sum_ref;
	
	// DUT outputs (Matching TopModule 1-bit specification)
	logic cout_dut;
	logic sum_dut;

	// Helper task to display signals in required formats
	task display_signals(input $time current_time,
		input logic in_a,
		input logic in_b,
		input logic in_cin,
		input logic ref_cout,
		input logic dut_cout,
		input logic ref_sum,
		input logic dut_sum);
	begin
		$display("======================================================