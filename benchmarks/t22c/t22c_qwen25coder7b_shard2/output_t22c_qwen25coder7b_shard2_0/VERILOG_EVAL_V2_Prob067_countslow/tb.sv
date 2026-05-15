`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	pushbutton rstbtn,
	pushbutton ena,
	special_signal slowena,
	output reg slowena_out,
	output reg reset_out,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match,
	output wire ref_valid,
	output wire [7:0] ref_value,
	input [7:0] ref_value_i,
	input ref_update_en,
	input rst_en
);
	assign slowena_out = ena;
	assign reset_out = rstbtn;
	assign wavedrom_enable = ena;
	assign wavedrom_title = "Testbench";
	assign ref_valid = tb_match;
	assign ref_value = ref_value_i;

	task reset_test(input async=0);
		bit arfail, srfail, datafail;

		@(posedge clk);
		@(posedge clk) reset_out <= 0;
		repeat(3) @(posedge clk);

		@(negedge clk) begin datafail = !tb_match ; reset_out <= 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
			srfail = !tb_match;
			reset_out <= 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.

	endtask

	task wavedrom_start(input[511:0] title = "");
	endtask
	
task wavedrom_stop;
		#1;
	endtask	
	
	reg hint1;
	initial begin
		reset_out <= 1;
		ena <= 1;
		wavedrom_start("Synchronous reset and counting.");
		reset_test();
		repeat(12) @(posedge clk);
		wavedrom_stop();
		@(posedge clk);

		//wavedrom_start("Testing.");
		reset_out <= 1;
		@(posedge clk);
		reset_out <= 0;
		repeat(9) @(posedge clk);
		ena <= 0;
		@(negedge clk) hint1 = tb_match;
		repeat(3) @(posedge clk);
		if (hint1 && !tb_match) begin
			$display ("Hint: What is supposed to happen when the counter is 9 and not enabled?");
		end
		//wavedrom_stop();
		ena <= 1;
		reset_out <= 1;
		@(posedge clk);
		reset_out <= 0;

		wavedrom_start("Enable/disable");
		repeat(15) @(posedge clk) ena <= !($random & 1);
		wavedrom_stop();
		@(posedge clk);

		repeat(400) @(posedge clk, negedge clk) begin
			ena <= !($random&3);
			reset_out <= !($random & 31);
		end
		#1 $finish;
	end

endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;

		int clocks;
	} stats;
	
	stats stats1;
	

	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic slowena;
	logic reset;
	logic [3:0] q_ref;
	logic [3:0] q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,ena,reset,q_ref,q_dut );
	end

	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk(clk),
		.rstbtn(reset),
		.ena(slowena),
		.slowena(slowena),
		.reset_out(slowena),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable),
		.tb_match(tb_match),
		.ref_valid(ref_valid),
		.ref_value(ref_value),
		.ref_value_i(ref_value_i),
		.ref_update_en(ref_update_en),
		.rst_en(rst_en)
	);
	RefModule good1 (
		.clk(clk),
		.slowena(slowena),
		.reset(reset),
		.q(q_ref) );
	
	TopModule top_module1 (
		.clk(clk),
		.slowena(slowena),
		.reset(reset),
		.q(q_dut) );
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	
	
	final begin
		if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
		else $display("Hint: Output '%s' has no mismatches.", "q");
				
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		if (stats1.errors == 0) $display("SIMULATION PASSED");
		else $display("SIMULATION FAILED - %1d MISMATCHES DETECTED, FIRST AT TIME %1d", stats1.errors, stats1.errortime_q);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin if (stats1.errors_q == 0) stats1.errortime_q = $time;
			stats1.errors_q = stats1.errors_q+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule