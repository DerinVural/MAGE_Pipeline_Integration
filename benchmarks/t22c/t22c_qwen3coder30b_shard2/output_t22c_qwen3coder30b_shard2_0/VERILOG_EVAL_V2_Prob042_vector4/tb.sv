`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] in
);

	initial begin
		repeat(100) @(posedge clk, negedge clk)
			in <= $random;
		$finish;
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

	logic [7:0] in;
	logic [31:0] out_ref;
	logic [31:0] out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end


	wire tb_match;      // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	RefModule good1 (
		.in,
		.out(out_ref) );
		
	TopModule top_module1 (
		.in,
		.out(out_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	// Queue for storing inputs and outputs for mismatch display
	reg [7:0] input_queue [$];
	reg [31:0] got_output_queue [$];
	reg [31:0] golden_queue [$];

	localparam MAX_QUEUE_SIZE = 10;

	// Check for mismatch and display details
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;

		// Push values to queues
		if (input_queue.size() >= MAX_QUEUE_SIZE - 1) begin
			input_queue.delete(0);
			got_output_queue.delete(0);
			golden_queue.delete(0);
		end

		input_queue.push_back(in);
		got_output_queue.push_back(out_dut);
		golden_queue.push_back(out_ref);

		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
			
			// Display mismatch details
			$display("Mismatch detected at time %t", $time);
			$display("Input: %h (%b), Got Output: %h (%b), Expected Output: %h (%b)",
				in, in, out_dut, out_dut, out_ref, out_ref);
			
			// Display last 10 cycles
			$display("Last %d cycles:", input_queue.size());
			for (int i = 0; i < input_queue.size(); i++) begin
				$display("Cycle %d: Input %h (%b), Got %h (%b), Expected %h (%b)",
					i, input_queue[i], input_queue[i],
					got_output_queue[i], got_output_queue[i],
					golden_queue[i], golden_queue[i]);
			end
		end
		
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; 
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
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule