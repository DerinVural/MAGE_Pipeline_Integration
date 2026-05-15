`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

typedef struct packed {
	int errors;
	int errortime;
	int errors_Y1;
	int errortime_Y1;
	int errors_Y3;
	int errortime_Y3;

	int clocks;
} stats;

stats stats1;

wire [511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic [5:0] y;
logic w;
logic Y1_ref;
logic Y1_dut;
logic Y3_ref;
logic Y3_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,y,w,Y1_ref,Y1_dut,Y3_ref,Y3_dut);
end

wire tb_match; 	wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk(clk),
	.* ,
	.y(y),
	.w(w)
);
RefModule good1 (
	.y(y),
	.w(w),
	.Y1(Y1_ref),
	.Y3(Y3_ref)
);

TopModule top_module1 (
	.y(y),
	.w(w),
	.Y1(Y1_dut),
	.Y3(Y3_dut)
);

bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;
		@(strobe);
	end
endtask

final begin
	if (stats1.errors_Y1) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Y1", stats1.errors_Y1, stats1.errortime_Y1);
	else $display("Hint: Output '%s' has no mismatches.", "Y1");
	if (stats1.errors_Y3) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Y3", stats1.errors_Y3, stats1.errortime_Y3);
	elese $display("Hint: Output '%s' has no mismatches.", "Y3");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	if (stats1.errors == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
availi
