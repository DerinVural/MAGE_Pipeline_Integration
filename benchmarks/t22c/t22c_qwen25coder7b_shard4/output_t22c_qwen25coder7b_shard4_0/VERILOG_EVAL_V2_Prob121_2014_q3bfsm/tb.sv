`timescale 1 ps/1 ps

module stimulus_gen (
	input clk,
	output logic reset,
	output logic x
);

	random seed;
	integer seed_random;
	real random_real;
	notify notif;

	initial begin
		seed_random = $random(seed);
		seed_random = seed_random + 1;
		$random(seed);
		seed_random = $random(seed);
		seed_random = seed_random + 1;
		$random(seed);
		reset = 1;
		x = 0;
		repeat(10) @(posedge clk);
		reset = 0;
		repeat(10) @(posedge clk);
		@notif.wait;
		repeat(500) @(negedge clk) begin
			seed_random = seed_random + 1;
			$random(seed);
			x = ($random(seed)) ? 1 : 0;
			seed_random = seed_random + 1;
			$random(seed);
			repeat(10) @(posedge clk);
		end
		$finish;
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

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;

logic reset;
logic x;
logic z_ref;
logic z_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,x,z_ref,z_dut );
end

wire tb_match;  // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk(clk),
	.reset(reset),
	.x(x)
);
RefModule good1 (
	.clk(clk),
	.reset(reset),
	.x(x),
	.z(z_ref)
);

TopModule top_module1 (
	.clk(clk),
	.reset(reset),
	.x(x),
	.z(z_dut)
);

bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
endtask	
final begin
	if (stats1.errors_z) begin
		$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0t", stats1.errortime_z);
		$display("First mismatch occurred with inputs: clk=%0t, reset=%0t, x=%0t, expected z=%0t, got z=%0t", stats1.errortime_z-10, stats1.errortime_z-9, stats1.errortime_z-8, stats1.errortime_z-7, stats1.errortime_z-6);
	end else begin
		$display("SIMULATION PASSED");
	end

	$display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0t.", stats1.errors_z, stats1.errortime_z);
	$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end

assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

always @(posedge clk, negedge clk) begin
	stats1.clocks++;
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
	begin
		if (stats1.errors_z == 0) stats1.errortime_z = $time;
		stats1.errors_z = stats1.errors_z+1'b1;
	end
end

initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule
