`timescale 1ps/1ps

module stimulus_gen(
	input clk,
	output reg reset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
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
		$display("Hint: Your reset doesn't seem to be working");
	else if (arfail && (async || !datafail))
		$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");	// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
	// a functionality error than the reset being implemented asynchronously.

display("wavedrom_title: %h", wavedrom_title);
display("wavedrom_enable: %b", wavedrom_enable);

endtask
task wavedrom_start(input[511:0] title = "/");	display("wavedrom_title set to: %s", title);
endtask
task wavedrom_stop;	#1;
endtask	systemverilog
Stats stats1;
systemverilog
initial begin
	reset <= 1;
	wavedrom_start("Synchronous reset");
	reset_test(false);
	repeat(5) @(posedge clk);
	wavedrom_stop();
	systemverilog	reset <= 0;
	systemverilog	repeat(989) @(negedge clk);
	systemverilog	wavedrom_start("Wrap around behaviour");
	systemverilog	repeat(14) @(posedge clk);
	systemverilog	wavedrom_stop();
	systemverilog	repeat(2000) @(posedge clk, negedge clk) begin
	systemverilog		reset <= !($random & 127);
	systemverilog	end
	systemverilog	reset <= 0;
	systemverilog	repeat(2000) @(posedge clk);
	systemverilog	#1 $finish;
systemverilog
end

endmodule

module tb;
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
logic reset;
logic [9:0] q_ref;
logic [9:0] q_dut;
initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,q_ref,q_dut);
end
wire tb_match;  wire tb_mismatch = ~tb_match;
stimulus_gen stim1(
	.clk,
	.*,
	.reset
);
RefModule good1(
	.clk,
	.reset,
	.q(q_ref)
);
TopModule top_module1(
	.clk,
	.reset,
	.q(q_dut)
);
always @(posedge clk, negedge clk) begin
	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (q_ref !== (q_ref ^ q_dut ^ q_ref))
	begin if (stats1.errors_q == 0) stats1.errortime_q = $time;
		stats1.errors_q++;
	end
end
initial begin
	if (stats1.errors_q) $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors_q, stats1.errortime_q);
	else $display("SIMULATION PASSED");
	#1 $finish;
end
endmodule