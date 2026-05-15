`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// --- stimulus_gen (Copied as per golden testbench structure) ---
module stimulus_gen (
	input clk,
	output logic areset,
	output logic bump_left,
	output logic bump_right,
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
	{bump_right, bump_left} <= 3'h3;
	wavedrom_start("Asynchronous reset");
	reset_test(1);
	repeat(3) @(posedge clk);
	{bump_right, bump_left} <= 2;
	repeat(2) @(posedge clk);
	{bump_right, bump_left} <= 1;
	repeat(2) @(posedge clk);
	wavedrom_stop();
	
	@(posedge clk);
	repeat(200) @(posedge clk, negedge clk) begin
		{bump_right, bump_left} <= $random & $random;
		reset <= !($random & 31);
	end

	#1 $finish;
end
	endmodule


// --- tb Module (Improved Golden Testbench) ---
module tb();

	// Stats structure, cleaned up to avoid syntax errors from previous attempts
	typedef struct packed {
		int errors;
		int errortime;
		int errors_walk_left;
		int errortime_walk_left;
		int errors_walk_right;
		int errortime_walk_right;
		int clocks;
		// Tracking variables for detailed logging
		logic [511:0] first_mismatch_inputs_val;
		logic [511:0] first_mismatch_expected_val;
		logic [511:0] first_mismatch_actual_val;
		int first_mismatch_time_left;
		int first_mismatch_time_right;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic areset;
	logic bump_left;
	logic bump_right;
	logic walk_left_ref;
	logic walk_left_dut;
	logic walk_right_ref;
	logic walk_right_dut;

	// Variables to track first mismatch details
	logic [511:0] first_mismatch_inputs_track;
	integer first_mismatch_time_track_left = -1;
	integer first_mismatch_time_track_right = -1;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,bump_left,bump_right,walk_left_ref,walk_left_dut,walk_right_ref,walk_right_dut );
	end


	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus generator
	stimulus_gen stim1 (
		.clk,
		.* , 
		.areset,
		.bump_left,
		.bump_right );
	
	// Reference Model
	RefModule good1 (
		.clk,
		.areset,
		.bump_left,
		.bump_right,
		.walk_left(walk_left_ref),
		.walk_right(walk_right_ref) );
		
	// DUT Instance
	TopModule top_module1 (
		.clk,
		areset,
		bump_left,
		bump_right,
		.walk_left(walk_left_dut),
		.walk_right(walk_right_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	endtask
	

	// Capture current inputs for mismatch reporting (Triggered on positive clock edge)
	always_ff @(posedge clk)
	begin
		if (!tb_mismatch) // Capture inputs when there is NO mismatch (to track context)
			first_mismatch_inputs_track <= {bump_right, bump_left, areset};
		else
			// Reset tracking if mismatch occurs, as we only care about the FIRST instance
			first_mismatch_inputs_track <= {1'b0, 1'b0, 1'b0};
		end
	
	// Verification assignment: DUT must equal Reference
	assign tb_match = ( { walk_left_ref, walk_right_ref } === { walk_left_dut, walk_right_dut } );
	
	// Verification and Statistics Update
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Check overall match
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Check walk_left
		if (walk_left_ref !== walk_left_dut)
		begin 
			if (stats1.errors_walk_left == 0) begin 
			stats1.errortime_walk_left = $time;
			first_mismatch_time_track_left = $time;
			end
			sstats1.errors_walk_left = stats1.errors_walk_left+1'b1;
		end
		
		// Check walk_right
		if (walk_right_ref !== walk_right_dut)
		begin 
			if (stats1.errors_walk_right == 0) begin 
			sstats1.errortime_walk_right = $time;
			first_mismatch_time_track_right = $time;
			end
			sstats1.errors_walk_right = stats1.errors_walk_right+1'b1;
		end
		end

	// Final Reporting
	initial begin
		// Wait long enough to allow simulation to run its course
		@(negedge clk);
		
		// --- Detailed Mismatch Reporting for First Error ---
		if (stats1.errors_walk_left > 0) begin
			$display("
=======================================================");
			s$display("SIMULATION FAILED - Detailed Mismatch Detected for walk_left at time %0d", stats1.errortime_walk_left);
			$display("=======================================================");
			
			// Input signals at first mismatch
			$display("--- Input Signals (Time %0d) ---", stats1.errortime_walk_left);
			$display("CLK: %b", clk);
			$display("ARESET: %b", areset);
			$display("BUMP_LEFT: %b", bump_left);
			$display("BUMP_RIGHT: %b", bump_right);
			
			// Outputs at first mismatch
			$display("
--- Output Signals (Time %0d) ---", stats1.errortime_walk_left);
			// Displaying single bits in both formats as requested
			$display("DUT walk_left: %b (Hex: %h)", walk_left_dut, walk_left_dut);
			$display("REF walk_left: %b (Hex: %h)", walk_left_ref, walk_left_ref);
			$display("DUT walk_right: %b (Hex: %h)", walk_right_dut, walk_right_dut);
			$display("REF walk_right: %b (Hex: %h)", walk_right_ref, walk_right_ref);
			
			// Display the tracked inputs for context
			$display("
--- Context Inputs at First Mismatch Time ---");
			$display("Inputs (Reset, Bumps): %b (Hex: %h)", first_mismatch_inputs_track, first_mismatch_inputs_track);
		end
		
		if (stats1.errors_walk_right > 0) begin
			$display("
=======================================================");
			$display("SIMULATION FAILED - Detailed Mismatch Detected for walk_right at time %0d", stats1.errortime_walk_right);
			$display("=======================================================");
			
			// Input signals at first mismatch
			$display("--- Input Signals (Time %0d) ---", stats1.errortime_walk_right);
			$display("CLK: %b", clk);
			$display("ARESET: %b", areset);
			$display("BUMP_LEFT: %b", bump_left);
			$display("BUMP_RIGHT: %b", bump_right);
			
			// Outputs at first mismatch
			$display("
--- Output Signals (Time %0d) ---", stats1.errortime_walk_right);
			// Displaying single bits in both formats as requested
			$display("DUT walk_left: %b (Hex: %h)", walk_left_dut, walk_left_dut);
			$display("REF walk_left: %b (Hex: %h)", walk_left_ref, walk_left_ref);
			$display("DUT walk_right: %b (Hex: %h)", walk_right_dut, walk_right_dut);
			$display("REF walk_right: %b (Hex: %h)", walk_right_ref, walk_right_ref);
			
			// Display the tracked inputs for context
			$display("
--- Context Inputs at First Mismatch Time ---");
			$display("Inputs (Reset, Bumps): %b (Hex: %h)", first_mismatch_inputs_track, first_mismatch_inputs_track);
		end
		
		// --- Final Summary --- 
		if (stats1.errors == 0) begin
			$display("
*****************************************
SIMULATION PASSED
*****************************************
");
		end else begin
			$display("
=======================================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("=======================================================");
		end
		
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		
		$finish;
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule