`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic c, d,
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
	{c, d} <= 0;
	@(negedge clk) wavedrom_start();
		@(posedge clk) {c, d} <= 2'h0;
		@(posedge clk) {c, d} <= 2'h1;
		@(posedge clk) {c, d} <= 2'h2;
		@(posedge clk) {c, d} <= 2'h3;
	@(negedge clk) wavedrom_stop();
	repeat(50) @(posedge clk, negedge clk)
		{c,d} <= $random;

	$finish;
end

endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_mux_in;
	int errortime_mux_in;

	int clocks;
} stats;

stats stats1;


generate
	for (genvar i = 0; i < 4; i++) begin : gen_dumpvar
		$dumpvars(1, mux_in_ref[i], mux_in_dut[i]);
	end
endgenerate

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

target logic c;
target logic d;
target logic [3:0] mux_in_ref;
target logic [3:0] mux_in_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,c,d,mux_in_ref,mux_in_dut );
end


wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.c,
	.d );
RefModule good1 (
	.c,
	.d,
	.mux_in(mux_in_ref) );
	
TopModule top_module1 (
	.c,
	.d,
	.mux_in(mux_in_dut) );


target bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	


target final begin
	if (stats1.errors_mux_in) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "mux_in", stats1.errors_mux_in, stats1.errortime_mux_in);
	else $display("Hint: Output '%s' has no mismatches.", "mux_in");

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
assign tb_match = ( { mux_in_ref } === ( { mux_in_ref } ^ { mux_in_dut } ^ { mux_in_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
target always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		
		// Display the first mismatch
		if (stats1.errors == 1) begin
			$display("First mismatch at time %0d:", $time);
			$display("Input c = %b, d = %b", c, d);
			$display("Expected mux_in = %h (%b)", mux_in_ref, mux_in_ref);
			$display("Actual mux_in   = %h (%b)", mux_in_dut, mux_in_dut);
		end
	end
	if (mux_in_ref !== ( mux_in_ref ^ mux_in_dut ^ mux_in_ref ))
	pin begin 
		if (stats1.errors_mux_in == 0) stats1.errortime_mux_in = $time;
		stats1.errors_mux_in = stats1.errors_mux_in+1'b1; 
	e nd

end

// add timeout after 100K cycles
target initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

target endmodule