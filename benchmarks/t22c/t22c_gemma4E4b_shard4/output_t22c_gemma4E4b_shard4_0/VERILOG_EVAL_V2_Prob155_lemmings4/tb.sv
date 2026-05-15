`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic areset,
	output logic bump_left,
	output logic bump_right,
	output logic dig,
	output logic ground,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
	
	reg reset;
	assign areset = reset;

	task reset_test(input async=0);
	bit arfail, srfail, datafail;
	
	@(posedge clk);
	@(posedge clk) reset <= 0;
	repeat(3) @(posedge clk);
	
	@(negedge clk) begin datafail = !tb_match ; reset <= 1; end
	@(posedge clk) arfail = !tb_match;
	@(posedge clk) begin
	srfail = !tb_match;
	reset <= 0;
	end
	if (srfail)
	s$display("Hint: Your reset doesn't seem to be working.");
	else if (arfail && (async || !datafail))
	s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
	// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
	// a functionality error than the reset being implemented asynchronously.
	endtask


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");	endtask
	
task wavedrom_stop;
		#1;
	endtask


	initial begin
	reset <= 1'b1;
	@(posedge clk);
	reset <= 0;
	{bump_left, bump_right, ground, dig} <= 2;
	repeat(2) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 3;
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 10;
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 0;
	repeat(3) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 3;
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;
	repeat(4) @(posedge clk);
	
	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(20) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Survive
	repeat(1) @(posedge clk);

	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(21) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Splat after falling left
	repeat(20) @(posedge clk) begin
	{dig, bump_right, bump_left} <= $random & $random;	// See if it's handled correctly.
	ground <= |($random & 7);
	end
	
	reset <= 1;
	{bump_left, bump_right, ground, dig} <= 2;	// Normal
	@(posedge clk)
	reset <= 0;	// Resurrect.
	bump_left <= 1;
	repeat(5) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(21) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Splat after falling right
	repeat(20) @(posedge clk) begin
	{dig, bump_right, bump_left} <= $random & $random;	// See if it's handled correctly.
	ground <= |($random & 7);
	end

	reset <= 1;
	@(posedge clk)
	reset <= 0;	// Resurrect.
	{bump_left, bump_right, ground, dig} <= 2;	// Normal
wavedrom_start("Splat?");
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(24) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Splat? (24-cycles)
	repeat(2) @(posedge clk);
wavedrom_stop();
	
	reset <= 1;
	@(posedge clk)
	reset <= 0;	// Resurrect.
	{bump_left, bump_right, ground, dig} <= 2;	// Normal
	@(posedge clk);
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(35) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Splat? (Test for 5-bit non-saturating counter)
	repeat(2) @(posedge clk);
	repeat(20) @(posedge clk) begin
	{dig, bump_right, bump_left} <= $random & $random;	// See if it's handled correctly.
	ground <= |($random & 7);
	end

	reset <= 1;
	{bump_left, bump_right, ground, dig} <= 2;	// Normal
	@(posedge clk)
	reset <= 0;	// Resurrect.
	@(posedge clk);
	{bump_left, bump_right, ground, dig} <= 0;	// Fall
	repeat(67) @(posedge clk);
	{bump_left, bump_right, ground, dig} <= 2;	// Splat? (Test for 6-bit non-saturating counter)
	repeat(20) @(posedge clk) begin
	{dig, bump_right, bump_left} <= $random & $random;	// See if it's handled correctly.
	ground <= |($random & 7);
	end

	reset <= 1;
	{bump_left, bump_right, ground, dig} <= 2;	// Normal
	@(posedge clk)
	reset <= 0;	// Resurrect.
	
		repeat(400) @(posedge clk, negedge clk) begin
	{dig, bump_right, bump_left} <= $random & $random;
	ground <= |($random & 7);
	reset <= !($random & 31);
	end

	#1 $finish;
	end

endmodule

module tb();

	typedef struct packed {
	int errors;
	int errortime;
	int errors_walk_left;
	int errortime_walk_left;
	int errors_walk_right;
	int errortime_walk_right;
	int errors_aaah;
	int errortime_aaah;
	int errors_digging;
	int errortime_digging;
	int clocks;
}
stats;

stats stats1;


wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
	#5 clk = ~clk;


logic areset;
logic bump_left;
logic bump_right;
logic ground;
logic dig;
logic walk_left_ref;
logic walk_left_dut;
logic walk_right_ref;
logic walk_right_dut;
logic aaah_ref;
logic aaah_dut;
logic digging_ref;
logic digging_dut;


initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,bump_left,bump_right,ground,dig,walk_left_ref,walk_left_dut,walk_right_ref,walk_right_dut,aaah_ref,aaah_dut,digging_ref,digging_dut );
end


wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;


stimulus_gen stim1 (
	.clk,
	.* , 
	.areset,
	.bump_left,
	.bump_right,
	.ground,
	.dig );
RefModule good1 (
	.clk,
	.areset,
	.bump_left,
	.bump_right,
	.ground,
	.dig,
	.walk_left(walk_left_ref),
	.walk_right(walk_right_ref),
	.aaah(aaah_ref),
	.digging(digging_ref) );

TopModule top_module1 (
	.clk,
	.areset,
	.bump_left,
	.bump_right,
	.ground,
	.dig,
	.walk_left(walk_left_dut),
	.walk_right(walk_right_dut),
	.aaah(aaah_dut),
	.digging(digging_dut) );



bit strobe = 0;
task wait_for_end_of_timestep;
	repeat(5) begin
	strobe <= !strobe;  // Try to delay until the very end of the time step.
	@(strobe);
	endtask



// Helper task to display signals in required format
task display_signal(input string name, input logic val_ref, input logic val_dut, input logic expected_val);
begin
	$display("\n======================================================================\n");
	$display("FIRST MISMATCH DETECTED for signal: %s at time %0d ps", name, $time);
	$display("------------------------------------------------------------------------\n");
	$display("INPUT SIGNALS: clk=%b, areset=%b, bump_left=%b, bump_right=%b, ground=%b, dig=%b", 
		clk, areset, bump_left, bump_right, ground, dig);
	$display("OUTPUT SIGNALS (Reference vs DUT):\n");
	$display("  %s (Ref): %b (0x%h)", name, val_ref, val_ref);
	$display("  %s (DUT): %b (0x%h)", name, val_dut, val_dut);
	$display("  %s (Expected): %b (0x%h)", name, expected_val, expected_val);
	$display("======================================================================\n");
endtask


final begin
	if (stats1.errors == 0)
		$display("\n=========================================");
		$display("SIMULATION PASSED");
		$display("=========================================");
	else
		$display("\n======================================================================\n");
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		$display("======================================================================\n");

	// Detailed reporting for each signal type that had a first error
	if (stats1.errors_walk_left > 0 && wl_first_error_logged == 0) begin
	snapshot_wl.clk_snap = clk;
	snapshot_wl.areset_snap = areset;
	snapshot_wl.bump_left_snap = bump_left;
	snapshot_wl.bump_right_snap = bump_right;
	snapshot_wl.ground_snap = ground;
	snapshot_wl.dig_snap = dig;
	snapshot_wl.ref_out_snap = walk_left_ref;
	snapshot_wl.dut_out_snap = walk_left_dut;
	display_signal("walk_left", walk_left_ref, walk_left_dut, walk_left_ref);
	wl_first_error_logged = 1;
	end
	if (stats1.errors_walk_right > 0 && wr_first_error_logged == 0) begin
	snapshot_wr.clk_snap = clk;
	snapshot_wr.areset_snap = areset;
	snapshot_wr.bump_left_snap = bump_left;
	snapshot_wr.bump_right_snap = bump_right;
	snapshot_wr.ground_snap = ground;
	snapshot_wr.dig_snap = dig;
	snapshot_wr.ref_out_snap = walk_right_ref;
	snapshot_wr.dut_out_snap = walk_right_dut;
	display_signal("walk_right", walk_right_ref, walk_right_dut, walk_right_ref);
	wr_first_error_logged = 1;
	end
	if (stats1.errors_aaah > 0 && aaah_first_error_logged == 0) begin
	snapshot_aaah.clk_snap = clk;
	snapshot_aaah.areset_snap = areset;
	snapshot_aaah.bump_left_snap = bump_left;
	snapshot_aaah.bump_right_snap = bump_right;
	snapshot_aaah.ground_snap = ground;
	snapshot_aaah.dig_snap = dig;
	snapshot_aaah.ref_out_snap = aaah_ref;
	snapshot_aaah.dut_out_snap = aaah_dut;
	display_signal("aaah", aaah_ref, aaah_dut, aaah_ref);
	aaah_first_error_logged = 1;
	end
	if (stats1.errors_digging > 0 && dig_first_error_logged == 0) begin
	snapshot_dig.clk_snap = clk;
	snapshot_dig.areset_snap = areset;
	snapshot_dig.bump_left_snap = bump_left;
	snapshot_dig.bump_right_snap = bump_right;
	snapshot_dig.ground_snap = ground;
	snapshot_dig.dig_snap = dig;
	snapshot_dig.ref_out_snap = digging_ref;
	snapshot_dig.dut_out_snap = digging_dut;
	display_signal("digging", digging_ref, digging_dut, digging_ref);
	dig_first_error_logged = 1;
	end

	$display("\n--- SUMMARY ---");
	$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule

module RefModule (
	input logic clk,
	input logic areset,
	input logic bump_left,
	input logic bump_right,
	input logic ground,
	input logic dig,
	output logic walk_left,
	output logic walk_right,
	output logic aaah,
	output logic digging
);
	// Placeholder for RefModule implementation
	assign walk_left = 1'b0;
	assign walk_right = 1'b0;
	assign aaah = 1'b0;
	assign digging = 1'b0;
endmodule


topmodule TopModule (
	input logic clk,
	input logic areset,
	input logic bump_left,
	input logic bump_right,
	input logic ground,
	input logic dig,
	output logic walk_left,
	output logic walk_right,
	output logic aaah,
	output logic digging
);
	// Placeholder for TopModule implementation
	assign walk_left = 1'b0;
	assign walk_right = 1'b0;
	assign aaah = 1'b0;
	assign digging = 1'b0;
endmodule

module tb_mismatch;
	// Dummy module to satisfy stimulus_gen's dependency on tb_mismatch
endmodule