`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic in1, in2, in3
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{in1, in2, in3} <= $random;
		end
		
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


wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic in1;
logic in2;
logic in3;
logic out_ref;
logic out_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,in1,in2,in3,out_ref,out_dut );
end


wire tb_match;      // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.in1,
	.in2,
	.in3 );
RefModule good1 (
	.in1,
	.in2,
	.in3,
	.out(out_ref) );
	
TopModule top_module1 (
	.in1,
	.in2,
	.in3,
	.out(out_dut) );

bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	

// Queue-based simulation mismatch display
reg in1_queue [$];
reg in2_queue [$];
reg in3_queue [$];
reg out_dut_queue [$];
reg out_ref_queue [$];

localparam MAX_QUEUE_SIZE = 10;

always @(posedge clk, negedge clk) begin
	if (in1_queue.size() >= MAX_QUEUE_SIZE - 1) begin
		in1_queue.delete(0);
		in2_queue.delete(0);
		in3_queue.delete(0);
		out_dut_queue.delete(0);
		out_ref_queue.delete(0);
	end

	in1_queue.push_back(in1);
	in2_queue.push_back(in2);
	in3_queue.push_back(in3);
	out_dut_queue.push_back(out_dut);
	out_ref_queue.push_back(out_ref);

	// Check for first mismatch
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
		if (stats1.errors_out == 0) stats1.errortime_out = $time;
		stats1.errors_out = stats1.errors_out+1'b1;
		
		// Display first mismatch details
		$display("Mismatch detected at time %t", $time);
		$display("First mismatch details:");
		$display("Input in1 = %b, in2 = %b, in3 = %b", in1, in2, in3);
		$display("Output DUT = %b, Expected = %b", out_dut, out_ref);
		
		$display("\nLast %d cycles of simulation:", in1_queue.size());
		for (int i = 0; i < in1_queue.size(); i++) begin
			$display("Cycle %d, in1=%b, in2=%b, in3=%b, DUT=%b, Ref=%b",
				i,
				in1_queue[i],
				in2_queue[i],
				in3_queue[i],
				out_dut_queue[i],
				out_ref_queue[i]);
		end
	end
end

final begin
	if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
	else $display("Hint: Output '%s' has no mismatches.", "out");

	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	
	if (stats1.errors == 0) begin
		$display("SIMULATION PASSED");
	end else begin
		$display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors, stats1.errortime);
	end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
	begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
		stats1.errors_out = stats1.errors_out+1'b1; end

end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule