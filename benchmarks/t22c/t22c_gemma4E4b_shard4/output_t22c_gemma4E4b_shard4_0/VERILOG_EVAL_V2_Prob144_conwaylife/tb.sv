`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	input tb_match,
	input [255:0] q_ref,
	input [255:0] q_dut,
	output reg load,
	output reg[255:0] data
);

	logic errored = 0;
	int blinker_cycle = 0;

	initial begin
		data <= 3'h7;         // Simple blinker, period 2
		load <= 1;
		@(posedge clk);
		load <= 0;
		data <= 4'hx;
		errored = 0;
		blinker_cycle = 0;
		repeat(5) @(posedge clk) begin
		blinker_cycle++;
		if (!tb_match) begin
			if (!errored) begin
				errored = 1;
				$display("Hint: The first test case is a blinker (initial state = 256'h7). First mismatch occurred at cycle %0d.\nHint:", blinker_cycle);
			end
		end
		
		if (errored) begin
			$display ("Hint: Cycle %0d:         Your game state       Reference game state", blinker_cycle);
			for (int i=15;i>=0;i--) begin
				$display("Hint:   q[%3d:%3d]     %016b      %016b", i*16+15, i*16, q_dut [ i*16 +: 16 ], q_ref[ i*16 +: 16 ]);
			end
			$display("Hint:\nHint:\n");
		end
		
		data <= 48'h000200010007;    // Glider, Traveling diagonal down-right.
		load <= 1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		load <= 0;
		data <= 4'hx;
		errored = 0;
		blinker_cycle = 0;
		repeat(100) @(posedge clk) begin
		blinker_cycle++;
		if (!tb_match) begin
			if (!errored) begin
				errored = 1;
				$display("Hint: The second test case is a glider (initial state = 256'h000200010007). First mismatch occurred at cycle %0d.\nHint:", blinker_cycle);
			end
		end
		
		if (errored && blinker_cycle < 20) begin
			$display ("Hint: Cycle %0d:         Your game state       Reference game state", blinker_cycle);
			for (int i=15;i>=0;i--) begin
				$display("Hint:   q[%3d:%3d]     %016b      %016b", i*16+15, i*16, q_dut [ i*16 +: 16 ], q_ref[ i*16 +: 16 ]);
			end
			$display("Hint:\nHint:\n");
		end
		
		data <= 48'h0040001000ce;    // Acorn
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(2000) @(posedge clk);

		data <= {$random,$random,$random,$random,$random,$random,$random,$random};    // Some random test cases.
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(200) @(posedge clk);

		data <= {$random,$random,$random,$random,$random,$random,$random,$random}&
			{$random,$random,$random,$random,$random,$random,$random,$random}&
			{$random,$random,$random,$random,$random,$random,$random,$random}&
			{$random,$random,$random,$random,$random,$random,$random,$random};
		load <= 1;
		@(posedge clk);
		load <= 0;
		repeat(200) @(posedge clk);

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

	logic load;
	logic [255:0] data;
	logic [255:0] q_ref;
	logic [255:0] q_dut;

	// --- Queue Definitions for improved reporting ---
	// MAX_QUEUE_SIZE set to 10 as per requirement.
	localparam MAX_QUEUE_SIZE = 10;

	// Input signals to queue (load, data)
	reg load_queue_r; 
	reg [255:0] data_queue_r;
	
	// Output signals to queue (q_dut, q_ref)
	reg [255:0] q_dut_queue_r;
	reg [255:0] q_ref_queue_r;
	
	// Mismatch/Control signals
	reg tb_mismatch_queue_r;
	
	// Queues
	reg load_queue [$];
	reg [255:0] data_queue [$];
	reg [255:0] q_dut_queue [$];
	reg [255:0] q_ref_queue [$];
	reg tb_mismatch_queue [$];

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,load,data,q_ref,q_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.tb_match, // This is an input to stimulus_gen, so it must be driven
		.q_ref, 
		.q_dut, 
		.load, 
		.data 
	);
	
	RefModule good1 (
		.clk,
		.load,
		.data,
		.q(q_ref) 
	);
	
	TopModule top_module1 (
		.clk,
		.load,
		.data,
		.q(q_dut) 
	);

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end	task
	
	// Task to handle queueing and error display upon mismatch (Sequential Logic)
	task check_and_log_mismatch;
		begin
			// 1. Update queues (Must be synchronized with clock edge where mismatch is detected)
			load_queue.push_back(load);
			data_queue.push_back(data);
			q_dut_queue.push_back(q_dut);
			q_ref_queue.push_back(q_ref);
			tb_mismatch_queue.push_back(tb_mismatch);

			// Maintain queue size
			if (load_queue.size() >= MAX_QUEUE_SIZE - 1) begin
				load_queue.delete(0);
				data_queue.delete(0);
				q_dut_queue.delete(0);
				q_ref_queue.delete(0);
				tb_mismatch_queue.delete(0);
			end

			// 2. Check for first mismatch (Using the comparison that triggers the original testbench logic)
			if (tb_mismatch && stats1.errors == 0) begin
				// First mismatch detected
				$display("\n============================================================");
				$display("*** FIRST MISMATCH DETECTED AT TIME %0t ***", $time);
				$display("============================================================\n");
				$display("--- Last %0d cycles of history (Matching/Mismatched Comparison) ---", load_queue.size());

				for (int i = 0; i < load_queue.size(); i++) begin
					// Check if the mismatch state was true for this cycle in the queue
					if (tb_mismatch_queue[i]) begin
						$display("-> MISMATCH at Cycle %d (Time %0t):", i, $time - (load_queue.size() - 1 - i) * 10);
						$display("   Input Load: %b, Data: %h", load_queue[i], data_queue[i]);
						$display("   Got Q (DUT): %h", q_dut_queue[i]);
						$display("   Expected Q (Ref): %h", q_ref_queue[i]);
					end else begin
						$display("-> Match at Cycle %d", i);
					end
				end
			$display("============================================================\n");
				// Set a flag so this detailed log only prints once
				stats1.errors_q = 1; 
			end
		end
	endtask

	// Initialization
	initial begin 
		// Reset error tracking variables
		stats1.errors = 0;
		stats1.errortime = 0;
		stats1.errors_q = 0;
		stats1.errortime_q = 0;
		stats1.clocks = 0;
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

	// Clocked monitoring and error counting
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// Check 1: Original Error Counter
		if (tb_mismatch) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
		end
		
		// Check 2: Queue/Detailed Error Counter (using the original comparison logic)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1; 
		end
		end

		// Log data and check for mismatch *after* state update
		check_and_log_mismatch();
	end


	// Final reporting logic
	initial begin
		// Wait for a long time to ensure all tests run
		@(negedge clk);
		repeat(1000) @(posedge clk);

		// Final Output Formatting
		if (stats1.errors_q > 0) 
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
		else 
			$display("SIMULATION PASSED");
		
		$display("\n--- Summary ---");
		$display("Total mismatched samples (General): %1d out of %1d samples", stats1.errors, stats1.clocks);
		$display("Total mismatched samples (Queue Check): %1d out of %1d samples", stats1.errors_q, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	endmodule