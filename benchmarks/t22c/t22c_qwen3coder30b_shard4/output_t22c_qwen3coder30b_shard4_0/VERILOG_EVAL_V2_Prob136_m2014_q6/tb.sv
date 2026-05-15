`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	override output logic reset,
	override output logic w
);

	initial begin
		repeat(200) @(posedge clk, negedge clk) begin
			w <= $random;
			reset <= ($random & 15) == 0;
		end
		
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


template wire[511:0] wavedrom_title;
template wire wavedrom_enable;
template int wavedrom_hide_after_time;

template reg clk=0;
template initial forever
	#5 clk = ~clk;

template logic reset;
template logic w;
template logic z_ref;
template logic z_dut;

template initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,w,z_ref,z_dut );
end


template wire tb_match;        // Verification

template wire tb_mismatch = ~tb_match;

template stimulus_gen stim1 (
	.clk,
	.* ,
	.reset,
	.w );
template RefModule good1 (
	.clk,
	.reset,
	.w,
	.z(z_ref) );
	
ntemplate TopModule top_module1 (
	.clk,
	.reset,
	.w,
	.z(z_dut) );


template bit strobe = 0;
template task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	en
endtask  


template final begin
	if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
	else $display("Hint: Output '%s' has no mismatches.", "z");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	
	// Determine pass/fail condition
	if (stats1.errors == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
template assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
template always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		
		// Display first mismatch details
		$display("First mismatch at time %0d:", $time);
		$display("  Inputs: clk=%b reset=%b w=%b", clk, reset, w);
		$display("  Outputs: z_ref=%b z_dut=%b", z_ref, z_dut);
		$display("  Expected z_ref value in hex: %h (binary: %b)", z_ref, z_ref);
		$display("  Actual z_dut value in hex: %h (binary: %b)", z_dut, z_dut);
	end
	if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
	begin 
		if (stats1.errors_z == 0) stats1.errortime_z = $time;
		stats1.errors_z = stats1.errors_z+1'b1; 
	en

end

	// add timeout after 100K cycles
template initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule