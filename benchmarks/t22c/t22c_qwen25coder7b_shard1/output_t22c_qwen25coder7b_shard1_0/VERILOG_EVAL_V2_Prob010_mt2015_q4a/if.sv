module tb;

typedef struct packed {
	int errors;
	int errortime;
	int errors_z;
	int errortime_z;
	
	int clocks;
} stats;

stats stats1;

typedef logic[511:0] wavedrom_title;
typedef logic wavedrom_enable;
typedef int wavedrom_hide_after_time;

reg clk = 0;
initial forever
	#5 clk = ~clk;

logic x;
logic y;
logic z_ref;
logic z_dut;

initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,x,y,z_ref,z_dut );
end

wire tb_match;
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
	.clk,
	.* ,
	.x,
	.y);
RefModule good1 (
	.x,
	.y,
	.z(z_ref) );

TopModule top_module1 (
	.x,
	.y,
	.z(z_dut) );

bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
		strobe <= !strobe;
		@(strobe);
	end
endtask

final begin
	if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
	else $display("Hint: Output '%s' has no mismatches.", "z");

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
	begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
		stats1.errors_z = stats1.errors_z+1'b1; end
end

initial begin
	#1000000;
	$display("TIMEOUT");
	$finish();
end
endmodule