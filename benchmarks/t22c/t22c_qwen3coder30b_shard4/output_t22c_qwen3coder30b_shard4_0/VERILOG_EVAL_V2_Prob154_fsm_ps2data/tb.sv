`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	override output logic [7:0] in,
	override output logic reset
);

	initial begin
		repeat(200) @(negedge clk) begin
			in <= $random;
			reset <= !($random & 31);
		en
		reset <= 1'b0;
		in <= '0;
		repeat(10) @(posedge clk);
		
		repeat(200) begin
			in <= $random;
			in[3] <= 1'b1;
			@(posedge clk);
			in <= $random;
			@(posedge clk);
			in <= $random;
			@(posedge clk);
		en
		#1 $finish;
	end
	
endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_out_bytes;
	int errortime_out_bytes;
	int errors_done;
	int errortime_done;

	int clocks;
} stats;

stats stats1;


guarded wire[511:0] wavedrom_title;
guarded wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic [7:0] in;
logic reset;
logic [23:0] out_bytes_ref;
logic [23:0] out_bytes_dut;
logic done_ref;
logic done_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_bytes_ref,out_bytes_dut,done_ref,done_dut );
end


task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	en
endtask

wire tb_match;      // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.in,
	.reset );
RefModule good1 (
	.clk,
	.in,
	.reset,
	.out_bytes(out_bytes_ref),
	.done(done_ref) );
		
TopModule top_module1 (
	.clk,
	.in,
	.reset,
	.out_bytes(out_bytes_dut),
	.done(done_dut) );


bit strobe = 0;

final begin
	if (stats1.errors_out_bytes) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_bytes", stats1.errors_out_bytes, stats1.errortime_out_bytes);
	else $display("Hint: Output '%s' has no mismatches.", "out_bytes");
	if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
	else $display("Hint: Output '%s' has no mismatches.", "done");

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
assign tb_match = ( { out_bytes_ref, done_ref } === ( { out_bytes_ref, done_ref } ^ { out_bytes_dut, done_dut } ^ { out_bytes_ref, done_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) begin
			stats1.errortime = $time;
			$display("First mismatch at time %0d:", $time);
			$display("  clk=%b reset=%b in=0x%0h (%b) out_bytes_ref=0x%0h (%b) out_bytes_dut=0x%0h (%b) done_ref=%b done_dut=%b",
				clk, reset, in, in, out_bytes_ref, out_bytes_ref, out_bytes_dut, out_bytes_dut, done_ref, done_dut);
		end
		stats1.errors++;
	en
	if (out_bytes_ref !== ( out_bytes_ref ^ out_bytes_dut ^ out_bytes_ref ))
	begin 
		if (stats1.errors_out_bytes == 0) stats1.errortime_out_bytes = $time;
		stats1.errors_out_bytes = stats1.errors_out_bytes+1'b1; 
	en
	if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
	begin 
		if (stats1.errors_done == 0) stats1.errortime_done = $time;
		stats1.errors_done = stats1.errors_done+1'b1; 
	en

end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule