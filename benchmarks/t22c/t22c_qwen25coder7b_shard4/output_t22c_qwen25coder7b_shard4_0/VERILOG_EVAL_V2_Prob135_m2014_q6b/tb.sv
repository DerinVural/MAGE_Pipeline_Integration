`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input logic clk,
	output logic [2:0] y,
	output logic w
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{y,w} <= $random;
		end
		#1 $finish;
	end
endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_Y1;
		int errortime_Y1;
		int clocks;
	} stats;
	stats stats1;
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	reg logic clk = 0;
	initial forever
		#5 clk = ~clk;
	logic [2:0] y;
	logic w;
	logic Y1_ref;
	logic Y1_dut;
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,y,w,Y1_ref,Y1_dut );
	end
	wire tb_match;  	// Verification
	wire tb_mismatch = ~tb_match;
	stimulus_gen stim1 (
		.clk,
		.* ,
		.y,
		.w );
	RefModule good1 (
		.y,
		.w,
		.Y1(Y1_ref) );
	TopModule top_module1 (
		.y,
		.w,
		.Y1(Y1_dut) );
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@strobe;
		end
	endtask
	final begin
		if (stats1.errors_Y1) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_Y1, stats1.errortime_Y1);
		else $display("SIMULATION PASSED");
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	assign tb_match = ( { Y1_ref } === ( { Y1_ref } ^ { Y1_dut } ^ { Y1_ref } ) );
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (Y1_ref !== ( Y1_ref ^ Y1_dut ^ Y1_ref ))
		begin if (stats1.errors_Y1 == 0) stats1.errortime_Y1 = $time;
			stats1.errors_Y1 = stats1.errors_Y1+1'b1; end
	end
	// empty final block for timeout
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
endmodule