`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (Kept as is) ---
module stimulus_gen (
	input clk,
	output reg [2:0] vec,
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
		int count; count = 0;
		vec <= 3'b0;
		@(negedge clk);
		wavedrom_start();
		repeat(10) @(posedge clk)
			vec <= count++;
		wavedrom_stop();
		
		#1 $finish;
	end
	endmodule

// --- Reference Module ---
module RefModule (
	input logic [2:0] vec,
	output logic [2:0] outv,
	output logic o2,
	output logic o1,
	output logic o0
);
	// Implementation based on spec: outputs the same vector and splits it
	assign outv = vec;
	assign o0 = vec[0];
	assign o1 = vec[1];
	assign o2 = vec[2];
endmodule

// --- Top Module (DUT) ---
module TopModule (
	input  logic [2:0] vec,
	output logic [2:0] outv,
	output logic o2,
	output logic o1,
	output logic o0
);
	// Implementation based on spec: outputs the same vector and splits it
	assign outv = vec;
	assign o0 = vec[0];
	assign o1 = vec[1];
	assign o2 = vec[2];
endmodule

// --- Testbench ---
module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_outv;
		int errortime_outv;
		int errors_o2;
		int errortime_o2;
		int errors_o1;
		int errortime_o1;
		int errors_o0;
		int errortime_o0;
		int clocks;
		// Fields to store state at the time of FIRST mismatch
		logic [2:0] vec_err_outv_0;
		logic [2:0] outv_ref_err_outv_0;
		logic [2:0] outv_dut_err_outv_0;
		logic o2_ref_err_o2_0;
		logic o2_dut_err_o2_0;
		logic o1_ref_err_o1_0;
		logic o1_dut_err_o1_0;
		logic o0_ref_err_o0_0;
		logic o0_dut_err_o0_0;
	} stats;
	
	stats stats1;
	
	// Signals from stimulus_gen

	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic [2:0] vec;
	logic [2:0] outv_ref;
	logic [2:0] outv_dut;
	logic o2_ref;
	logic o2_dut;
	logic o1_ref;
	logic o1_dut;
	logic o0_ref;
	logic o0_dut;

	// Variables to capture state at first mismatch
	logic [2:0] captured_vec;
	logic [2:0] captured_outv_ref;
	logic [2:0] captured_outv_dut;
	logic captured_o2_ref;
	logic captured_o2_dut;
	logic captured_o1_ref;
	logic captured_o1_dut;
	logic captured_o0_ref;
	logic captured_o0_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen::stim1, tb_mismatch, vec, outv_ref, outv_dut, o2_ref, o2_dut, o1_ref, o1_dut, o0_ref, o0_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.vec
	);
	RefModule good1 (
		.vec,
		outv(outv_ref),
		o2(o2_ref),
		o1(o1_ref),
		o0(o0_ref) );
	TopModule top_module1 (
		.vec,
		outv(outv_dut),
		o2(o2_dut),
		o1(o1_dut),
		o0(o0_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask

	// Helper function to display multi-bit signals in HEX and BIN
	task display_signal(string name, logic [3:0] value);
	begin
		$display("  %-15s: HEX=%h, BIN=%b", name, value, value);
	endtask
	
	
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Check overall match
		tb_match = ( { outv_ref, o2_ref, o1_ref, o0_ref } === ( { outv_dut, o2_dut, o1_dut, o0_dut } ));
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// --- Output V Mismatch Check ---
		if (outv_ref !== outv_dut) begin
			if (stats1.errors_outv == 0) begin
			sstats1.errortime_outv = $time;
			// Capture state for first mismatch
			captured_vec = vec;
			captured_outv_ref = outv_ref;
			captured_outv_dut = outv_dut;
			end
			sstats1.errors_outv = stats1.errors_outv + 1'b1;
		end
		
		// --- O2 Mismatch Check ---
		if (o2_ref !== o2_dut) begin
			if (stats1.errors_o2 == 0) begin
			sstats1.errortime_o2 = $time;
			// Capture state for first mismatch
			captured_vec = vec;
			captured_o2_ref = o2_ref;
			captured_o2_dut = o2_dut;
			end
			sstats1.errors_o2 = stats1.errors_o2 + 1'b1;
		end
		
		// --- O1 Mismatch Check ---
		if (o1_ref !== o1_dut) begin
			if (stats1.errors_o1 == 0) begin
			sstats1.errortime_o1 = $time;
			// Capture state for first mismatch
			captured_vec = vec;
			captured_o1_ref = o1_ref;
			captured_o1_dut = o1_dut;
			end
			sstats1.errors_o1 = stats1.errors_o1 + 1'b1;
		end
		
		// --- O0 Mismatch Check ---
		if (o0_ref !== o0_dut) begin
			if (stats1.errors_o0 == 0) begin
			sstats1.errortime_o0 = $time;
			// Capture state for first mismatch
			captured_vec = vec;
			captured_o0_ref = o0_ref;
			captured_o0_dut = o0_dut;
			end
			sstats1.errors_o0 = stats1.errors_o0 + 1'b1;
		end
		end

	// add timeout after 100K cycles	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end
	
	// Final Reporting Logic
	initial begin
		@(negedge clk);
		#1; // Wait slightly after the last clock edge
		
		if (stats1.errors == 0) begin
			$display("
=========================================");
			$display("SIMULATION PASSED");
			$display("=========================================");
		end
		else begin
			// Determine the absolute earliest time of *any* mismatch
			int first_error_time = stats1.errortime;
			if (stats1.errortime_outv < first_error_time) first_error_time = stats1.errortime_outv;
			if (stats1.errortime_o2 < first_error_time) first_error_time = stats1.errortime_o2;
			if (stats1.errortime_o1 < first_error_time) first_error_time = stats1.errortime_o1;
			if (stats1.errortime_o0 < first_error_time) first_error_time = stats1.errortime_o0;
			
			$display("
=========================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_error_time);
			$display("=========================================");
			
			// Display Mismatch Details at the earliest time found
			$display("
--- Mismatch Details at Time %0d ps ---", first_error_time);
			
			// 1. Display Input Signals (vec)
			$display("
[INPUT SIGNALS] (vec)");
			display_signal("vec", captured_vec);
			
			// 2. Display Output Signals (Actual vs Expected)
			$display("
[OUTPUT SIGNALS] (Actual DUT vs Expected Reference)");
			
			// OutV (3 bits)
			display_signal("outv (Actual)", captured_outv_dut);
			display_signal("outv (Expected)", captured_outv_ref);
			// O2 (1 bit)
			display_signal("o2 (Actual)", captured_o2_dut);
			display_signal("o2 (Expected)", captured_o2_ref);
			// O1 (1 bit)
			display_signal("o1 (Actual)", captured_o1_dut);
			display_signal("o1 (Expected)", captured_o1_ref);
			// O0 (1 bit)
			display_signal("o0 (Actual)", captured_o0_dut);
			display_signal("o0 (Expected)", captured_o0_ref);
			
			$display("
Total Mismatches: %0d/%0d samples", stats1.errors, stats1.clocks);
		end
	endmodule
