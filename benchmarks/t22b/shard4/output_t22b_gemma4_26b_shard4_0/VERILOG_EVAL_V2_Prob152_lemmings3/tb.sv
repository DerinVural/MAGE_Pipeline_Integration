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
	end

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	wire [0:13][3:0] d = {
		4'h2,
		4'h2,
		4'h3,
		4'h2,
		4'ha,
		4'h2,
		4'h0,
		4'h0,
		4'h0,
		4'h3,
		4'h2,
		4'h2,
		4'h2,
		4'h2
	};
	
	initial begin
		reset <= 1'b1;
		{bump_left, bump_right, ground, dig} <= 4'h2;
		reset_test(1);

		reset <= 1'b1;
		@(posedge clk);
		reset <= 0;
		
		@(negedge clk);
		wavedrom_start("Digging");
		for (int i=0;i<14;i++)
			@(posedge clk) {bump_left, bump_right, ground, dig} <= d[i];
		wavedrom_stop();
		
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

	// Queue for mismatch display
	localparam MAX_QUEUE_SIZE = 10;
	logic [5:0] q_in_bump_l, q_in_bump_r, q_in_ground, q_in_dig, q_in_areset;
	logic [3:0] q_out_wl, q_out_wr, q_out_aaah, q_out_dig;
	logic [3:0] q_in_areset_vec;
	logic [3:0] q_out_vec;
	
	reg [5:0] input_queue_bump_l [$];
	reg [5:0] input_queue_bump_r [$];
	reg [5:0] input_queue_ground [$];
	reg [5:0] input_queue_dig [$];
	reg [5:0] input_queue_areset [$];
	reg [3:0] output_queue_wl [$];
	reg [3:0] output_queue_wr [$];
	reg [3:0] output_queue_aaah [$];
	reg [3:0] output_queue_digging [$];

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,bump_left,bump_right,ground,dig,walk_left_ref,walk_left_dut,walk_right_ref,walk_right_dut,aaah_ref,aaah_dut,digging_ref,digging_dut );
	end

	wire tb_match;    // Verification
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
t	.ground,
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
		end
	endtask	

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
		if (stats1.errors_aaah) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "aaah", stats1.errors_aaah, stats1.errortime_aaah);
		else $display("Hint: Output '%s' has no mismatches.", "aaah");
		if (stats1.errors_digging) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "digging", stats1.errors_digging, stats1.errortime_digging);
		else $display("Hint: Output '%s' has no mismatches.", "digging");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	assign tb_match = ( { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } === ( { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } ^ { walk_left_dut, walk_right_dut, aaah_dut, digging_dut } ^ { walk_left_ref, walk_right_ref, aaah_ref, digging_ref } ) );

	always @(posedge clk, negedge clk) begin
		// Queue management
		if (input_queue_bump_l.size() >= MAX_QUEUE_SIZE) begin
			input_queue_bump_l.delete(0);
			input_queue_bump_r.delete(0);
			input_queue_ground.delete(0);
			input_queue_dig.delete(0);
			input_queue_areset.delete(0);
			output_queue_wl.delete(0);
			output_queue_wr.delete(0);
			output_queue_aaah.delete(0);
			output_queue_digging.delete(0);
		end

		// Push current state
		input_queue_bump_l.push_back(bump_left);
		input_queue_bump_r.push_back(bump_right);
		input_queue_ground.push_back(ground);
		input_queue_dig.push_back(dig);
		input_queue_areset.push_back(areset);
		output_queue_wl.push_back(walk_left_dut);
		output_queue_wr.push_back(walk_right_dut);
		output_queue_aaah.push_back(aaah_dut);
		output_queue_digging.push_back(digging_dut);

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				$display("Mismatch detected at time %t", $time);
				$display("\nLast %0d cycles of simulation:", input_queue_bump_l.size());
				for (int i = 0; i < input_queue_bump_l.size(); i++) begin
					$display("Cycle %0d, areset=%b, bump_l=%b, bump_r=%b, ground=%b, dig=%b | Got: wl=%b wr=%b aaah=%b dig=%b, Exp: wl=%b wr=%b aaah=%b dig=%b", 
						i, input_queue_areset[i], input_queue_bump_l[i], input_queue_bump_r[i], input_queue_ground[i], input_queue_dig[i],
						output_queue_wl[i], output_queue_wr[i], output_queue_aaah[i], output_queue_digging[i],
						walk_left_ref, walk_right_ref, aaah_ref, digging_ref); // Note: Ref is hard to queue perfectly without more memory, showing DUT vs Ref logic via the loop
				end
				end
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end

		if (walk_left_ref !== ( walk_left_ref ^ walk_left_dut ^ walk_left_ref )) begin 
			if (stats1.errors_walk_left == 0) stats1.errortime_walk_left = $time;
			stats1.errors_walk_left = stats1.errors_walk_left+1'b1; 
		end
		if (walk_right_ref !== ( walk_right_ref ^ walk_right_dut ^ walk_right_ref )) begin 
			if (stats1.errors_walk_right == 0) stats1.errortime_walk_right = $time;
			stats1.errors_walk_right = stats1.errors_walk_right+1'b1; 
		end
		if (aaah_ref !== ( aaah_ref ^ aaah_dut ^ aaah_ref )) begin 
			if (stats1.errors_aaah == 0) stats1.errortime_aaah = $time;
			stats1.errors_aaah = stats1.errors_aaah+1'b1; 
		end
		if (digging_ref !== ( digging_ref ^ digging_dut ^ digging_ref )) begin 
			if (stats1.errors_digging == 0) stats1.errortime_digging = $time;
			stats1.errors_digging = stats1.errors_digging+1'b1; 
		end
	end

   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule