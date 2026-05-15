`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic areset,
	output logic bump_left,
	output logic bump_right,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable,
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
	endtask

	task wavedrom_start(input[511:0] title = "");
		wavedrom_enable = 1;
		wavedrom_title = title;
	endtask
	
	task wavedrom_stop;
		wavedrom_enable = 0;
		#1;
	endtask	

	initial begin
		reset <= 1'b1;
		{bump_right, bump_left} <= 2'b11;
		wavedrom_start("Asynchronous reset");
		reset_test(1);
		repeat(3) @(posedge clk);
		{bump_right, bump_left} <= 2'b10;
		repeat(2) @(posedge clk);
		{bump_right, bump_left} <= 2'b01;
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

	wire tb_match;    // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk(clk),
		.areset(areset),
		.bump_left(bump_left),
		.bump_right(bump_right),
		wavedrom_title(wavedrom_title),
		wavedrom_enable(wavedrom_enable),
		tb_match(tb_match)
	);

	RefModule good1 (
		.clk(clk),
		.areset(areset),
		.bump_left(bump_left),
		.bump_right(bump_right),
		.walk_left(walk_left_ref),
		.walk_right(walk_right_ref) 
	);
		
	TopModule top_module1 (
		.clk(clk),
		.areset(areset),
		.bump_left(bump_left),
		.bump_right(bump_right),
		.walk_left(walk_left_dut),
		.walk_right(walk_right_dut) 
	);

	bit mismatch_logged = 0;
	
	assign tb_match = ( { walk_left_ref, walk_right_ref } === ( { walk_left_ref, walk_right_ref } ^ { walk_left_dut, walk_right_dut } ^ { walk_left_ref, walk_right_ref } ) );

	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;

			if (!mismatch_logged) begin
				$display("FIRST MISMATCH DETECTED at time %0t:", $time);
				$display("Inputs: clk=%b, areset=%b, bump_left=%b, bump_right=%b", clk, areset, bump_left, bump_right);
				$display("Outputs: walk_left_dut=%b, walk_right_dut=%b", walk_left_dut, walk_right_dut);
				$display("Expected: walk_left_ref=%b, walk_right_ref=%b", walk_left_ref, walk_right_ref);
				mismatch_logged = 1;
			end
		end;

		if (walk_left_ref !== ( walk_left_ref ^ walk_left_dut ^ walk_left_ref ))
		begin if (stats1.errors_walk_left == 0) stats1.errortime_walk_left = $time;
			stats1.errors_walk_left = stats1.errors_walk_left+1'b1; end

		if (walk_right_ref !== ( walk_right_ref ^ walk_right_dut ^ walk_right_ref ))
		begin if (stats1.errors_walk_right == 0) stats1.errortime_walk_right = $time;
			stats1.errors_walk_right = stats1.errors_walk_right+1'b1; end
	end

   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end

		if (stats1.errors_walk_left) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "walk_left", stats1.errors_walk_left, stats1.errortime_walk_left);
		else $display("Hint: Output '%s' has no mismatches.", "walk_left");
		if (stats1.errors_walk_right) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "walk_right", stats1.errors_walk_right, stats1.errortime_walk_right);
		else $display("Hint: Output '%s' has no mismatches.", "walk_right");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule