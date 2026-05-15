`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic resetn,
	output logic [2:0] r,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
	reg reset;
	assign resetn = ~reset;

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
		#1;
	endtask
	
	
	initial begin
	reset <= 1;
	r <= 0;
	@(posedge clk);
	
	r <= 1;
	reset_test();
	r <= 0;
	wavedrom_start("");
	@(posedge clk) r <= 0;
	@(posedge clk) r <= 7;
	@(posedge clk) r <= 7;
	@(posedge clk) r <= 7;
	@(posedge clk) r <= 6;
	@(posedge clk) r <= 6;
	@(posedge clk) r <= 6;
	@(posedge clk) r <= 4;
	@(posedge clk) r <= 4;
	@(posedge clk) r <= 4;
	@(posedge clk) r <= 0;
	@(posedge clk) r <= 0;
	@(posedge clk) r <= 4;
	@(posedge clk) r <= 6;
	@(posedge clk) r <= 7;
	@(posedge clk) r <= 7;
	@(posedge clk) r <= 7;
	@(negedge clk);
	wavedrom_stop();
	
	@(posedge clk);
	reset <= 0;
	@(posedge clk);
	@(posedge clk);
	
	repeat(500) @(negedge clk) begin
	reset <= ($random & 63) == 0;
	r <= $random;
	end
	
	#1 $finish;
	end
	endmodule

module tb();

	typedef struct packed {
	int errors;
	int errortime;
	int errors_g;
	int errortime_g;
		int clocks;
	} stats;
	
	stats stats1;
	


wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
initial forever
		#5 clk = ~clk;


logic resetn;
logic [2:0] r;
logic [2:0] g_ref;
logic [2:0] g_dut;


// Signals to capture state at first mismatch
logic [2:0] r_err_log;
logic [2:0] g_dut_err_log;
logic [2:0] g_ref_err_log;
logic resetn_err_log;


initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stimulus_gen.clk, tb_match ,clk,resetn,r,g_ref,g_dut );
end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk, 
		.resetn, 
		r, 
		wavedrom_title, 
		wavedrom_enable, 
		tb_match
);
ref_module good1 (
		.clk, 
		.resetn, 
		r, 
		g(g_ref) 
);
	top_module top_module1 (
		.clk, 
		.resetn, 
		r, 
		g(g_dut) 
);
	
	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	

final begin
	// Check for 'g' output mismatches first
	if (stats1.errors_g > 0) begin
		s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors_g, stats1.errortime_g);
		s$display("First 'g' mismatch details at time %0d ps:", stats1.errortime_g);
		// Displaying inputs (clk, resetn, r) and outputs (g_dut, g_ref) in HEX and BIN format
		s$display("  Inputs: clk=%0b, resetn=%0b, r=%0h (%0b)", clk, resetn, r, r);
		s$display("  Outputs: g_dut=%0h (%0b), g_ref=%0h (%0b)", g_dut, g_dut, g_ref, g_ref);
	end

	// Check for general mismatches
	if (stats1.errors > 0) begin
		s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
		s$display("First general mismatch details at time %0d ps:", stats1.errortime);
		// Displaying inputs (clk, resetn, r) and outputs (g_dut, g_ref) in HEX and BIN format
		s$display("  Inputs: clk=%0b, resetn=%0b, r=%0h (%0b)", clk, resetn, r, r);
		s$display("  Outputs: g_dut=%0h (%0b), g_ref=%0h (%0b)", g_dut, g_dut, g_ref, g_ref);
	end

	// Final PASS/FAIL summary
	if (stats1.errors == 0 && stats1.errors_g == 0)
		s$display("SIMULATION PASSED");
	else begin
		// If errors exist, the specific failure messages above already printed the required format.
		end
	
	$display("Simulation finished at %0d ps", $time);
	end


// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { g_ref } === ( { g_ref } ^ { g_dut } ^ { g_ref } ) );

// Clocked logic and error tracking
always @(posedge clk, negedge clk) begin
	stats1.clocks++;

	// Log state for general mismatch detection
	if (!tb_match) begin
		if (stats1.errors == 0) begin
		stats1.errortime = $time;
		r_err_log <= r;
	g_dut_err_log <= g_dut;
	g_ref_err_log <= g_ref;
	resetn_err_log <= resetn;
		end
	stats1.errors++;
	end
	
	// Log state for 'g' output mismatch detection
	if (g_ref !== ( g_ref ^ g_dut ^ g_ref ))
	begin 
		if (stats1.errors_g == 0) begin
		stats1.errortime_g = $time;
		r_err_log <= r;
	g_dut_err_log <= g_dut;
	g_ref_err_log <= g_ref;
	resetn_err_log <= resetn;
	end
	stats1.errors_g++; // Increment for every clock cycle, regardless of mismatch, to count samples.
	end
	endmodule


// Dummy modules required by the original testbench to compile
module ref_module;
	input logic clk;
	input logic resetn;
	input logic [2:0] r;
	output logic [2:0] g;
endmodule


top_module top_module_dummy;
	input logic clk;
	input logic resetn;
	input logic [2:0] r;
	output logic [2:0] g;
endmodule