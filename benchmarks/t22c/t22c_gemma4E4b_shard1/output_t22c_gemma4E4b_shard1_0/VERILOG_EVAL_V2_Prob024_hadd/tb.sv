`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (Kept as is) ---
module stimulus_gen (
	input clk,
	output logic a,b
);
	
always @(posedge clk, negedge clk)
		{a,b} <= $random;
	
	initial begin
		repeat(100) @(negedge clk);
		$finish;
	end
	endmodule

// --- Reference Module (Placeholder for compilation) ---
module RefModule (
	input a,
	input b,
	output sum,
	output cout
);
	// Placeholder implementation for compilation
	assign sum = a ^ b;
	assign cout = a & b;
endmodule

// --- Top Module Definition (Matches required interface) ---
module TopModule (
    input logic a,
    input logic b,
    output logic sum,
    output logic cout
);
    // Implementation is assumed to be provided externally, using simple logic for simulation completeness
    assign sum = a ^ b;
    assign cout = a & b;
endmodule


// =========================================
// Testbench Module (Improved) 
// =========================================
module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_sum;
		int errortime_sum;
		int errors_cout;
		int errortime_cout;
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
reg clk=0;
initial forever
		#5 clk = ~clk;

logic a;
logic b;
logic sum_ref;
logic sum_dut;
logic cout_ref;
logic cout_dut;

initial begin 
		$dumpfile("wave.vcd");
		// Dump signals from stimulus_gen instance (stim1) and top level (tb)
		$dumpvars(1, stimulus_gen::stim1, tb);
	end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.* , 
		a,
		b );
	
RefModule good1 (
		a,
		b,
		sum(sum_ref),
		.cout(cout_ref) );
	
TopModule top_module1 (
		a,
		b,
		sum(sum_dut),
		.cout(cout_dut) );


bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
task
	// Empty task placeholder if needed, but removing the redundant bare task
endtask


// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { sum_ref, cout_ref } === ( { sum_ref, cout_ref } ^ { sum_dut, cout_dut } ^ { sum_ref, cout_ref } ) );

// --- Mismatch Logging Logic ---
always @(posedge clk, negedge clk) begin
	
	stats1.clocks++;
	
	// Primary Mismatch Tracking
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		
		// Detailed Logging on FIRST Overall Mismatch
		if (stats1.errors == 1) begin
			$display("
======================================================");
			$display("*** FIRST MISMATCH DETECTED at Time %0d ps ***", $time);
			$display("------------------------------------------------------");
			$display("Inputs: a = %b, b = %b", a, b);
			$display("Reference Outputs: sum_ref = %b, cout_ref = %b", sum_ref, cout_ref);
			$display("DUT Outputs: sum_dut = %b, cout_dut = %b", sum_dut, cout_dut);
			$display("======================================================