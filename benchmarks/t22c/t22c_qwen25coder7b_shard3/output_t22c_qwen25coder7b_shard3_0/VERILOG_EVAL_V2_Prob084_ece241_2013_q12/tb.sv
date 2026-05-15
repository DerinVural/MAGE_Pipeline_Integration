module tb();
typedef struct packed {
	int errors;
	int errortime;
	int errors_Z;
	int errortime_Z;
	int clocks;
} stats;

stats stats1;
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
reg clk=0;
logic enable;
logic S;
logic A;
logic B;
logic C;
logic Z_ref;
logic Z_dut;
bit strobe;
signal tb_match;
signal tb_mismatch;

initial forever
#	5 clk = ~clk;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,enable,S,A,B,C,Z_ref,Z_dut );
end

wire tb_match;
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk(clk),
	.enable(enable),
	.S(S),
	.A(A),
	.B(B),
	.C(C),
	.wavedrom_title(wavedrom_title),
	.wavedrom_enable(wavedrom_enable)
);
RefModule good1 (
	.clk(clk),
	.enable(enable),
	.S(S),
	.A(A),
	.B(B),
	.C(C),
	.Z(Z_ref)
);

TopModule top_module1 (
	.clk(clk),
	.enable(enable),
	.S(S),
	.A(A),
	.B(B),
	.C(C),
	.Z(Z_dut)
);

final begin
	if (stats1.errors_Z) $display("Hint: Output 'Z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_Z, stats1.errortime_Z);
	esle $display("Hint: Output 'Z' has no mismatches.");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end

signal tb_match;
signal tb_mismatch;
endmodule