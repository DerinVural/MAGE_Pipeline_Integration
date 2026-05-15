`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// NOTE: RefModule is assumed to be defined elsewhere as it was not provided.
// For compilation purposes, a minimal placeholder is added here.
module RefModule (
    input  clk,
    input  areset,
    input  load,
    input  ena,
    input  [3:0] data,
    output [3:0] q
);
    // Placeholder implementation to allow testbench structure to compile
    assign q = 4'h0;
endmodule

module stimulus_gen (
	input clk,
	output areset,
	output reg load,
	output reg ena,
	output reg[3:0] data,
	
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
			s$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask
	
	
	initial begin
		{load, ena, reset, data} <= 7'h40;
		@(posedge clk) {load, ena, reset, data} <= 7'h4f;
		wavedrom_start("Load and reset");
		@(posedge clk) {load, ena, reset, data} <= 7'h0x;
		@(posedge clk) {load, ena, reset, data} <= 7'h2x;
		@(posedge clk) {load, ena, reset, data} <= 7'h2x;
		@(posedge clk) {load, ena, reset, data} <= 7'h0x;
		reset_test(1);
		@(posedge clk);
		@(posedge clk);
		wavedrom_stop();
		
		repeat(400) @(posedge clk, negedge clk) begin
			reset <= !($random & 31);
			load <= !($random & 15);
			ena <= |($random & 31);
			data <= $random;
		end
		h#1 $finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;

		int clocks;
		
		// Variables to capture state at first error
		logic [3:0] q_dut_at_error;
		logic [3:0] q_ref_at_error;
		logic [3:0] data_at_error;
		
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic areset;
	logic load;
	logic ena;
	logic [3:0] data;
	logic [3:0] q_ref;
	logic [3:0] q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,load,ena,data,q_ref,q_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.areset, // Note: The golden TB passed '.*' for stimulus_gen, implying it handles the inputs. We map the required inputs here.
		.load,
		ena,
		.data,
		.tb_match
	);
	RefModule good1 (
		.clk,
		areset,
		.load,
		ena,
		.data,
		.q(q_ref) );
	
	TopModule top_module1 (
		.clk,
		areset,
		.load,
		ena,
		.data,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end	task
	
	
	// --- Error Logging and Display Tasks ---
	task display_error_details;
		input $time t_err;
		input [3:0] q_ref_val;
		input [3:0] q_dut_val;
		input [3:0] data_val;
		
		$display("========================================================================");
		$display("*** MISMATCH DETECTED AT TIME %0d ps ***", t_err);
		$display("------------------------------------------------------------------------");
		$display("INPUTS:");
		$display("  Data: HEX=%h, BIN=%b", data_val, data_val);
		$display("OUTPUTS:");
		$display("  Q_REF: HEX=%h, BIN=%b", q_ref_val, q_ref_val);
		$display("  Q_DUT: HEX=%h, BIN=%b", q_dut_val, q_dut_val);
		$display("========================================================================");
	endtask

	// --- Final Reporting Logic ---
	initial begin
		@(negedge clk);
		// Wait a little extra time to ensure final states are captured before $finish
		#10;
		
		if (stats1.errors == 0 && stats1.errors_q == 0) begin
			$display("\n****************************************");
			$display("SIMULATION PASSED");
			$display("****************************************\n");
		end else begin
			string result_msg;
			if (stats1.errors > 0) begin
				result_msg = $sformatf("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			end else begin
				// This branch should ideally not be hit if errors_q > 0 but errors == 0
				result_msg = $sformatf("SIMULATION FAILED - 0 MISMATCHES DETECTED, FIRST AT TIME %0d (Output Mismatch Only)", stats1.errortime_q);
			end
			$display("\n****************************************");
			$display("%s", result_msg);
			$display("****************************************\n");
		end
	end

	// Initialization of statistics
	initial begin
		stats1.errors = 0;
		stats1.errortime = 0;
		stats1.errors_q = 0;
		stats1.errortime_q = 0;
		stats1.clocks = 0;
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;

		// 1. Check Total Mismatch
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			stats1.q_dut_at_error = q_dut;
			stats1.q_ref_at_error = q_ref;
			stats1.data_at_error = data;
			end
			s$display("--- Total Mismatch Detected ---");
			display_error_details($time, q_ref, q_dut, data);
			stats1.errors++;
		end

		// 2. Check Output Mismatch (Original logic preserved)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) begin
			stats1.errortime_q = $time;
			stats1.q_dut_at_error = q_dut;
			stats1.q_ref_at_error = q_ref;
			stats1.data_at_error = data;
			end
			s$display("--- Output Mismatch Detected ---");
			display_error_details($time, q_ref, q_dut, data);
			stats1.errors_q = stats1.errors_q+1'b1;
		end
	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED. Terminating simulation.");
     $finish();
   end

endmodule