`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [3:0] x,
	output logic [3:0] y
);
	randomize(x, y)
	repeat(100) @(posedge clk, negedge clk) begin
		{x,y} = {y,x} + $random;
	end
	#1 $finish;
endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_sum;
		int errortime_sum;
		int clocks;
	} stats;
	params WIDTH = 4;
	stats stats1;
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	reg clk=0;
	initial forever
		#5 clk = ~clk;
	logic [WIDTH-1:0] x;
	logic [WIDTH-1:0] y;
	logic [(WIDTH*2)-1:0] sum_ref;
	logic [(WIDTH*2)-1:0] sum_dut;
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,x,y,sum_ref,sum_dut );
	end
	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	stimulus_gen stim1 (
		.clk(clk),
		.*,
		.x,
		.y );
	TopModule top_module1 (
		.x,
		.y,
		.sum(sum_dut) );
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;       // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask
	final begin
		if (stats1.errors_sum) $display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime_sum);
		else $display("SIMULATION PASSED");
		$display("TOTAL ERROR COUNT: %1d", stats1.errors);
		$display("Simulation finished at %0d ps", $time);
	end
	assign tb_match = ( { sum_ref } === ( { sum_ref } ^ { sum_dut } ^ { sum_ref } ) );
	automatic @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (sum_ref !== ( sum_ref ^ sum_dut ^ sum_ref )) begin
			if (stats1.errors_sum == 0) stats1.errortime_sum = $time;
			stats1.errors_sum = stats1.errors_sum + 1'b1;
		end
	end
	signal wire tb_mismatch;
	initial begin
		#1000000;
		$display("TIMEOUT");
		$finish();
	end
endmodule