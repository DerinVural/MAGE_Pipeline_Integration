`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic [7:0] in,
	output logic reset
);

	initial begin
		repeat(200) @(negedge clk) begin
			in <= $random;
			reset <= !($random & 31);
		end

		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_done;
		int errortime_done;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [7:0] in;
	logic reset;
	logic done_ref;
	logic done_dut;

	// Queue declarations for mismatch display
	logic [7:0] input_queue [$];
	logic done_got_queue [$];
	logic done_golden_queue [$];
	logic reset_queue [$];
	localparam MAX_QUEUE_SIZE = 5;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,done_ref,done_dut );
	end


	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in,
		.reset );
	RefModule good1 (
		.clk,
		.in,
		.reset,
		.done(done_ref) );
		
	TopModule top_module1 (
		.clk,
		.in,
		.reset,
		.done(done_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	
	final begin
		if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
		else $display("Hint: Output '%s' has no mismatches.", "done");

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
	assign tb_match = ( { done_ref } === ( { done_ref } ^ { done_dut } ^ { done_ref } ) );
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		
		// Queue management
		if (input_queue.size() >= MAX_QUEUE_SIZE - 1) begin
			input_queue.delete(0);
			done_got_queue.delete(0);
			done_golden_queue.delete(0);
			reset_queue.delete(0);
		end
		input_queue.push_back(in);
		done_got_queue.push_back(done_dut);
		done_golden_queue.push_back(done_ref);
		reset_queue.push_back(reset);

		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				$display("Mismatch detected at time %t", $time);
				$display("\nLast %0d cycles of simulation:", input_queue.size());
				for (int i = 0; i < input_queue.size(); i++) begin
					if (done_got_queue[i] === done_golden_queue[i]) begin
						$display("Got Match at");
					end else begin
						$display("Got Mismatch at");
					end
					$display("Cycle %0d, reset %b, input %h (%b), got output %h, exp output %h",
						i,
						reset_queue[i],
						input_queue[i], input_queue[i],
						done_got_queue[i],
						done_golden_queue[i]
					);
				end
			end
			stats1.errors++;
		end
		if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
		begin if (stats1.errors_done == 0) stats1.errortime_done = $time;
			stats1.errors_done = stats1.errors_done+1'b1; end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule