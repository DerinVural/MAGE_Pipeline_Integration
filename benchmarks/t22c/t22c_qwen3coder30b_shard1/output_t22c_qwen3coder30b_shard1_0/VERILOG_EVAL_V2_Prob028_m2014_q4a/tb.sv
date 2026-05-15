`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic d, ena
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{d,ena} <= $random;
		end
		
		#1 $finish;
	end
	
endmodule

module tb();

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

logic d;
logic ena;
logic q_ref;
logic q_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,d,ena,q_ref,q_dut );
end


task wait_for_end_of_timestep;
	repeat(5) begin
		#1;  // Simple delay to wait for end of timestep
	end
endtask	

wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.d,
	.ena );
RefModule good1 (
	.d,
	.ena,
	.q(q_ref) );
	
TopModule top_module1 (
	.d,
	.ena,
	.q(q_dut) );


bit strobe = 0;

final begin
	if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
	else $display("Hint: Output '%s' has no mismatches.", "q");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	
	// Display the simulation result based on whether mismatches occurred
	if (stats1.errors == 0)
		$display("SIMULATION PASSED");
	else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		// Display the signals when the first mismatch occurs
		if (stats1.errors == 1) begin
			$display("First mismatch details:");
			$display("Time=%0d, d=%b, ena=%b, q_ref=%b, q_dut=%b", stats1.errortime, d, ena, q_ref, q_dut);
		end
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
	begin 
		if (stats1.errors_q == 0) stats1.errortime_q = $time;
		stats1.errors_q = stats1.errors_q+1'b1; 
	end

end

   // add timeout after 100K cycles
   initial begin
	 #1000000
	 $display("TIMEOUT");
	 $finish();
   end

endmodule