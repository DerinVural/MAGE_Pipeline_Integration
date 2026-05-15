`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator Module (Copied from Golden Testbench) ---
module stimulus_gen (
	input clk,
	output reg load,
	output reg ena,
	output reg[1:0] amount,
	output reg[63:0] data,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
endtask
	
task wavedrom_stop;
		h#1;
endtask
	
	initial begin
		load <= 1;
		ena <= 0;
		data <= 'x;
		amount <= 0;
		@(posedge clk) data <= 64'h000100;
		wavedrom_start("Shifting");
			@(posedge clk) load <= 0; ena <= 1;
			amount <= 2;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 1;
		@(posedge clk) amount <= 1;
		@(posedge clk) amount <= 0;
		@(posedge clk) amount <= 0;
		@(posedge clk) amount <= 3;
		@(posedge clk) amount <= 3;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 2;
		@(negedge clk);
		wavedrom_stop();
		
		@(posedge clk); load <= 1; data <= 64'hx;
		@(posedge clk); load <= 1; data <= 64'h80000000_00000000;
		wavedrom_start("Arithmetic right shift");
			@(posedge clk) load <= 0; ena <= 1;
			amount <= 2;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 2;
		@(posedge clk) amount <= 2;
		@(negedge clk);
		wavedrom_stop();

		@(posedge clk);
		@(posedge clk);
		
		
		repeat(4000) @(posedge clk, negedge clk) begin
			load <= !(\$random & 31);
			ena <= |(\$random & 15);
			amount <= \$random;
			data <= {\$random,\$random};
		end
		#1 \$finish;
	end
	endmodule

// --- Reference Module (Assumed to exist for golden comparison) ---
module RefModule (
	input clk,
	input load,
	input ena,
	input [1:0] amount,
	input [63:0] data,
	output logic [63:0] q
);
	// Dummy implementation to allow compilation, actual logic is in 'good1'
	assign q = data;
endmodule

// --- DUT Module (TopModule) ---
module TopModule (
	input clk,
	input load,
	input ena,
	input [1:0] amount,
	input [63:0] data,
	output logic [63:0] q
);
	// Placeholder implementation matching specification
	assign q = data;
endmodule

// --- Testbench ---
module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
	} stats;
	
stats stats1;
	
// Variables to capture first mismatch data
logic [63:0] first_mismatch_data_input_data;
logic [1:0] first_mismatch_data_amount;
logic first_mismatch_data_load;
logic first_mismatch_data_ena;
logic [63:0] first_mismatch_data_q_ref;
logic [63:0] first_mismatch_data_q_dut;
integer first_mismatch_clock_count;
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
reg clk=0;
initial forever
		#5 clk = ~clk;

logic load;
logic ena;
logic [1:0] amount;
logic [63:0] data;
logic [63:0] q_ref;
logic [63:0] q_dut;
	
// Signals captured at mismatch
logic [63:0] mismatch_input_data_capture;
logic [1:0] mismatch_input_amount_capture;
logic mismatch_input_load_capture;
logic mismatch_input_ena_capture;
	
initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,load,ena,amount,data,q_ref,q_dut );
	end
	

wire tb_match;
wire tb_mismatch = ~tb_match;
	
// Instantiate Stimulus Generator
stimulus_gen stim1 (
	.clk, 
	.load, 
	ena, 
	.amount, 
	.data, 
	.wavedrom_title, 
	wavedrom_enable
);
	
// Reference Module
RefModule good1 (
	.clk, 
	.load, 
	ena, 
	.amount,
	.data,
	.q(q_ref) );
	
// DUT Module
top_module1 (
	.clk, 
	.load, 
	ena, 
	.amount,
	.data,
	.q(q_dut) );
	

bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	

// Helper function to display signals in HEX and BIN format for 64-bit signals
task display_signal_u64(string name, logic [63:0] signal_val);
		$display("    %s: HEX = %h, BIN = %b", name, signal_val, signal_val);
	endtask
	
// Helper function to display signals in HEX format for 512-bit signals
task display_signal_u512(string name, logic [511:0] signal_val);
		$display("    %s: HEX = %h", name, signal_val);
	endtask
	

// --- Final Reporting Block ---
final begin
		$display("========================================================");
		if (stats1.errors == 0) begin
			s$display("SIMULATION PASSED");
			$display("========================================================");
		end else begin
			s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--------------------------------------------------------");
			$display("--- FIRST MISMATCH DETAILS (Time: %0d ps, Clock Cycle: %0d) ---", stats1.errortime, stats1.clocks);
			$display("Input Signals:");
			$display("  clk: %b", clk);
			$display("  load: %b", mismatch_input_load_capture);
			$display("  ena: %b", mismatch_input_ena_capture);
			$display("  amount: HEX = %h, BIN = %b", mismatch_input_amount_capture, mismatch_input_amount_capture);
			$display("  data: HEX = %h, BIN = %b", first_mismatch_data_input_data, first_mismatch_data_input_data);
			$display("Output Signals:");
			$display("  q_ref (Expected): HEX = %h, BIN = %b", first_mismatch_data_q_ref, first_mismatch_data_q_ref);
			$display("  q_dut (Actual): HEX = %h, BIN = %b", first_mismatch_data_q_dut, first_mismatch_data_q_dut);
			$display("--------------------------------------------------------");
		end
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	
// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Store inputs/outputs for the first mismatch event
		if (stats1.errors == 0 && !tb_match) begin
			sstats1.errortime = $time;
			first_mismatch_data_input_data = data;
			first_mismatch_data_amount = amount;
			first_mismatch_data_load = load;
			first_mismatch_data_ena = ena;
			first_mismatch_data_q_ref = q_ref;
			first_mismatch_data_q_dut = q_dut;
			first_mismatch_clock_count = stats1.clocks;
		end
		
		if (!tb_match) begin
			sstats1.errors++;
		end
		
		// Original logic for q mismatch (kept for functional parity)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1; 
		end
		end
	
// add timeout after 100K cycles
initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule