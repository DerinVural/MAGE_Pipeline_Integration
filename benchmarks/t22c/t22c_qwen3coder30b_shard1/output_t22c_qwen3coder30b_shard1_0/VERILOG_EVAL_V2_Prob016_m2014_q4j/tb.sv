`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [3:0] x,y
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{x,y} <= $random;
		end
		
		#1 $finish;
	end
	
endmodule

module tb();

typedef struct packed {
	int errors;
	int errortime;
	int errors_sum;
	int errortime_sum;

	int clocks;
} stats;

stats stats1;


generate
	for (genvar i = 0; i < 5; i++) begin : gen_sum_ref
		assign sum_ref[i] = (i < 4) ? (x[i] ^ y[i] ^ (i > 0 ? sum_ref[i-1] : 1'b0)) : sum_ref[i-1];
	end
endgenerate

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic [3:0] x;
logic [3:0] y;
logic [4:0] sum_ref;
logic [4:0] sum_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,x,y,sum_ref,sum_dut );
end


generate
	for (genvar i = 0; i < 5; i++) begin : gen_sum_ref
		assign sum_ref[i] = (i < 4) ? (x[i] ^ y[i] ^ (i > 0 ? sum_ref[i-1] : 1'b0)) : sum_ref[i-1];
	end
endgenerate

wire tb_match; 		// Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.x,
	.y );
RefModule good1 (
	.x,
	.y,
	.sum(sum_ref) );
	
TopModule top_module1 (
	.x,
	.y,
	.sum(sum_dut) );


bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	


final begin
	if (stats1.errors_sum) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "sum", stats1.errors_sum, stats1.errortime_sum);
	else $display("Hint: Output '%s' has no mismatches.", "sum");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	
	if (stats1.errors_sum == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_sum, stats1.errortime_sum);
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { sum_ref } === ( { sum_ref } ^ { sum_dut } ^ { sum_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (sum_ref !== ( sum_ref ^ sum_dut ^ sum_ref ))
	pin begin 
		if (stats1.errors_sum == 0) begin
			stats1.errortime_sum = $time;
			// Display first mismatch details
			$display("FIRST MISMATCH AT TIME %0d:", $time);
			$display("Input x = %b (%h)", x, x);
			$display("Input y = %b (%h)", y, y);
			$display("Expected sum = %b (%h)", sum_ref, sum_ref);
			$display("Actual sum   = %b (%h)", sum_dut, sum_dut);
		end
		stats1.errors_sum = stats1.errors_sum+1'b1; 
	end

end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule