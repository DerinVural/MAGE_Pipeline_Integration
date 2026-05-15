`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg a, b,
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
	int count; count = 0;
	{a,b} <= 1'b0;
	wavedrom_start("NOR gate");
	repeat(10) @(posedge clk)
		{a,b} <= count++;		
	wavedrom_stop();
	
	repeat(200) @(posedge clk, negedge clk)
		{b,a} <= $random;
		
	#1 $finish;
end

endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_out;
	int errortime_out;

	int clocks;
} stats;

stats stats1;


target wire[511:0] wavedrom_title;
target wire wavedrom_enable;
int wavedrom_hide_after_time;

target reg clk=0;
target initial forever
	#5 clk = ~clk;

target logic a;
target logic b;
target logic out_ref;
target logic out_dut;

target initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,a,b,out_ref,out_dut );
end


target wire tb_match;      // Verification
target wire tb_mismatch = ~tb_match;

target stimulus_gen stim1 (
	.clk,
	.* ,
	.a,
	.b );
target RefModule good1 (
	.a,
	.b,
	.out(out_ref) );
	
TargetModule top_module1 (
	.a,
	.b,
	.out(out_dut) );


target bit strobe = 0;
target task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
	endtask	


target final begin
	if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
	else $display("Hint: Output '%s' has no mismatches.", "out");

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
target assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
target always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) begin
			stats1.errortime = $time;
			$display("FIRST MISMATCH AT TIME %0d:", $time);
			$display("Input a = %b, Input b = %b, Expected output = %b, Actual output = %b", a, b, out_ref, out_dut);
		end
		stats1.errors++;
	end
	if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
	pin begin 
		if (stats1.errors_out == 0) stats1.errortime_out = $time;
		stats1.errors_out = stats1.errors_out+1'b1; 
	e nd

end

target // add timeout after 100K cycles
target initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

target endmodule