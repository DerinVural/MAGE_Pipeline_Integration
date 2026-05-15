`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


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
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	
	endtask


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
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

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_walk_left;
		int errortime_walk_left;
		int errors_walk_right;
		int errortime_walk_right;

		int clocks;
	} stats;
	
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
	logic walk_left_ref;
	logic walk_left_dut;
	logic walk_right_ref;
	logic walk_right_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,bump_left,bump_right,walk_left_ref,walk_left_dut,walk_right_ref,walk_right_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.areset,
		.bump_left,
		.bump_right );
	RefModule good1 (
		.clk,
		.areset,
		.bump_left,
		.bump_right,
		.walk_left(walk_left_ref),
		.walk_right(walk_right_ref) );
		
	TopModule top_module1 (
		.clk,
		.areset,
		.bump_left,
		.bump_right,
		.walk_left(walk_left_dut),
		.walk_right(walk_right_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	// Queue-based simulation mismatch display
	localparam MAX_QUEUE_SIZE = 5;
	logic areset_queue [$];
	logic bump_left_queue [$];
	logic bump_right_queue [$];
	logic walk_left_dut_queue [$];
	logic walk_right_dut_queue [$];
	logic walk_left_ref_queue [$];
	logic walk_right_ref_queue [$];
	bit mismatch_displayed = 0;
	
	
	final begin
		if (stats1.errors_walk_left) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "walk_left", stats1.errors_walk_left, stats1.errortime_walk_left);
		else $display("Hint: Output '%s' has no mismatches.", "walk_left");
		if (stats1.errors_walk_right) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "walk_right", stats1.errors_walk_right, stats1.errortime_walk_right);
		else $display("Hint: Output '%s' has no mismatches.", "walk_right");

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
	assign tb_match = ( { walk_left_ref, walk_right_ref } === ( { walk_left_ref, walk_right_ref } ^ { walk_left_dut, walk_right_dut } ^ { walk_left_ref, walk_right_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (walk_left_ref !== ( walk_left_ref ^ walk_left_dut ^ walk_left_ref ))
		begin if (stats1.errors_walk_left == 0) stats1.errortime_walk_left = $time;
			stats1.errors_walk_left = stats1.errors_walk_left+1'b1; end
		if (walk_right_ref !== ( walk_right_ref ^ walk_right_dut ^ walk_right_ref ))
		begin if (stats1.errors_walk_right == 0) stats1.errortime_walk_right = $time;
			stats1.errors_walk_right = stats1.errors_walk_right+1'b1; end

		// Queue management - trim if needed
		if (areset_queue.size() >= MAX_QUEUE_SIZE - 1) begin
			areset_queue.delete(0);
			bump_left_queue.delete(0);
			bump_right_queue.delete(0);
			walk_left_dut_queue.delete(0);
			walk_right_dut_queue.delete(0);
			walk_left_ref_queue.delete(0);
			walk_right_ref_queue.delete(0);
		end
		
		// Push current values to queues
		areset_queue.push_back(areset);
		bump_left_queue.push_back(bump_left);
		bump_right_queue.push_back(bump_right);
		walk_left_dut_queue.push_back(walk_left_dut);
		walk_right_dut_queue.push_back(walk_right_dut);
		walk_left_ref_queue.push_back(walk_left_ref);
		walk_right_ref_queue.push_back(walk_right_ref);
		
		// Display first mismatch with queue content
		if (!tb_match && !mismatch_displayed) begin
			mismatch_displayed = 1;
			$display("Mismatch detected at time %t", $time);
			$display("\nLast %d cycles of simulation:", areset_queue.size());
			
			for (int i = 0; i < areset_queue.size(); i++) begin
				if (walk_left_dut_queue[i] === walk_left_ref_queue[i] && walk_right_dut_queue[i] === walk_right_ref_queue[i]) begin
					$display("Got Match at");
				end else begin
					$display("Got Mismatch at");
				end
				$display("Cycle %d, reset %b, bump_left %b, bump_right %b, got walk_left %b walk_right %b, exp walk_left %b walk_right %b",
					i,
					areset_queue[i],
					bump_left_queue[i],
					bump_right_queue[i],
					walk_left_dut_queue[i],
					walk_right_dut_queue[i],
					walk_left_ref_queue[i],
					walk_right_ref_queue[i]
				);
			end
		end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule