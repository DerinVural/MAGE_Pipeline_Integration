`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] a, b,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

task wavedrom_start(input[511:0] title = "");
	endtask

task wavedrom_stop;
	#1;
endtask	


initial begin
	{a, b} <= 0;
	@(negedge clk) wavedrom_start();
		@(posedge clk) {a, b} <= 16'h0;
		@(posedge clk) {a, b} <= 16'h0070;
		@(posedge clk) {a, b} <= 16'h7070;
		@(posedge clk) {a, b} <= 16'h7090;
		@(posedge clk) {a, b} <= 16'h9070;
		@(posedge clk) {a, b} <= 16'h9090;
		@(posedge clk) {a, b} <= 16'h90ff;
	@(negedge clk) wavedrom_stop();
	repeat(100) @(posedge clk, negedge clk)
		{a,b} <= $random;

	$finish;
end

endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_s;
	int errortime_s;
	int errors_overflow;
	int errortime_overflow;

	int clocks;
} stats;

stats stats1;


target wire[511:0] wavedrom_title;
target wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

target logic [7:0] a;
target logic [7:0] b;
target logic [7:0] s_ref;
target logic [7:0] s_dut;
target logic overflow_ref;
target logic overflow_dut;

target wire tb_match;      // Verification
target wire tb_mismatch = ~tb_match;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,a,b,s_ref,s_dut,overflow_ref,overflow_dut );
end

stimulus_gen stim1 (
	.clk,
	.* ,
	.a,
	.b );
RefModule good1 (
	.a,
	.b,
	.s(s_ref),
	.overflow(overflow_ref) );

TopModule top_module1 (
	.a,
	.b,
	.s(s_dut),
	.overflow(overflow_dut) );


bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	


final begin
	if (stats1.errors_s) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "s", stats1.errors_s, stats1.errortime_s);
	else $display("Hint: Output '%s' has no mismatches.", "s");
	if (stats1.errors_overflow) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "overflow", stats1.errors_overflow, stats1.errortime_overflow);
	else $display("Hint: Output '%s' has no mismatches.", "overflow");

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
assign tb_match = ( { s_ref, overflow_ref } === ( { s_ref, overflow_ref } ^ { s_dut, overflow_dut } ^ { s_ref, overflow_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Display first mismatch details in hex and binary
			$display("First mismatch at time %0d:", $time);
			$display("Input a = %h (%b)", a, a);
			$display("Input b = %h (%b)", b, b);
			$display("Expected s = %h (%b)", s_ref, s_ref);
			$display("Actual s = %h (%b)", s_dut, s_dut);
			$display("Expected overflow = %b", overflow_ref);
			$display("Actual overflow = %b", overflow_dut);
		end
		stats1.errors++;
	end
	if (s_ref !== ( s_ref ^ s_dut ^ s_ref ))
	begin 
		if (stats1.errors_s == 0) stats1.errortime_s = $time;
		stats1.errors_s = stats1.errors_s+1'b1; 
	end
	if (overflow_ref !== ( overflow_ref ^ overflow_dut ^ overflow_ref ))
	begin 
		if (stats1.errors_overflow == 0) stats1.errortime_overflow = $time;
		stats1.errors_overflow = stats1.errors_overflow+1'b1; 
	end

end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule