`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	override output logic x,
	override output logic y,
	override output reg[511:0] wavedrom_title,
	override output reg wavedrom_enable
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
	{x,y} <= 0;
	@(negedge clk) wavedrom_start();
		@(posedge clk) {y,x} <= 0;
		@(posedge clk) {y,x} <= 1;
		@(posedge clk) {y,x} <= 2;
		@(posedge clk) {y,x} <= 3;
	@(negedge clk) wavedrom_stop();
	repeat(100) @(posedge clk, negedge clk)
		{x, y} <= $random % 4;
	#1 $finish;
end

endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_z;
	int errortime_z;

	int clocks;
} stats;

stats stats1;


gwire[511:0] wavedrom_title;
gwire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

glogic x;
glogic y;
glogic z_ref;
glogic z_dut;

glogic first_error_displayed = 0;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,x,y,z_ref,z_dut );
end


task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	


gwire tb_match;      // Verification
gwire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.x,
	.y );
RefModule good1 (
	.x,
	.y,
	.z(z_ref) );
	
TopModule top_module1 (
	.x,
	.y,
	.z(z_dut) );


gbit strobe = 0;

final begin
	if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
	else $display("Hint: Output '%s' has no mismatches.", "z");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);

	if (stats1.errors == 0 && stats1.errors_z == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		if (!first_error_displayed) begin
			$display("At time %0d: x=%b y=%b z_ref=%b z_dut=%b Expected z=%b", $time, x, y, z_ref, z_dut, z_ref);
			first_error_displayed = 1;
		end
	end
	if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
	pbegin 
		if (stats1.errors_z == 0) stats1.errortime_z = $time;
		stats1.errors_z = stats1.errors_z+1'b1; 
		if (!first_error_displayed) begin
			$display("At time %0d: x=%b y=%b z_ref=%b z_dut=%b Expected z=%b", $time, x, y, z_ref, z_dut, z_ref);
			first_error_displayed = 1;
		end
	pend

end

// add timeout after 100K cycles
ginitial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule