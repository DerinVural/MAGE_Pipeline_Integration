`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg d, done_counting, ack,
	output reg [9:0] state,
	input tb_match
);

	initial begin
		{d, done_counting, ack} <= 3'h0;
		state <= 10'h0;
		
		repeat(300) @(posedge clk, negedge clk) begin
			{d, done_counting, ack} = $random;
			state <= 1<< ($unsigned($random) % 10);
		end
		
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_B3_next;
		int errortime_B3_next;
		int errors_S_next;
		int errortime_S_next;
		int errors_S1_next;
		int errortime_S1_next;
		int errors_Count_next;
		int errortime_Count_next;
		int errors_Wait_next;
		int errortime_Wait_next;
		int errors_done;
		int errortime_done;
		int errors_counting;
		int errortime_counting;
		int errors_shift_ena;
		int errortime_shift_ena;
		
		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic d;
	logic done_counting;
	logic ack;
	logic [9:0] state;
	logic B3_next_ref;
	logic B3_next_dut;
	logic S_next_ref;
	logic S_next_dut;
	logic S1_next_ref;
	logic S1_next_dut;
	logic Count_next_ref;
	logic Count_next_dut;
	logic Wait_next_ref;
	logic Wait_next_dut;
	logic done_ref;
	logic done_dut;
	logic counting_ref;
	logic counting_dut;
	logic shift_ena_ref;
	logic shift_ena_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_match, d, done_counting, ack, state, B3_next_ref, B3_next_dut, S_next_ref, S_next_dut, S1_next_ref, S1_next_dut, Count_next_ref, Count_next_dut, Wait_next_ref, Wait_next_dut, done_ref, done_dut, counting_ref, counting_dut, shift_ena_ref, shift_ena_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;

	stimulus_gen stim1 (
		.clk, 
		.d, done_counting, ack, state, tb_match );
	RefModule good1 (
		d, done_counting, ack, state, 
		.B3_next(B3_next_ref),
		.S_next(S_next_ref),
		.S1_next(S1_next_ref),
		.Count_next(Count_next_ref),
		.Wait_next(Wait_next_ref),
		done(done_ref),
		.counting(counting_ref),
		.shift_ena(shift_ena_ref) );
	
	TopModule top_module1 (
		d, done_counting, ack, state, 
		.B3_next(B3_next_dut),
		.S_next(S_next_dut),
		.S1_next(S1_next_dut),
		.Count_next(Count_next_dut),
		.Wait_next(Wait_next_dut),
		done(done_dut),
		.counting(counting_dut),
		.shift_ena(shift_ena_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask

	
task check_and_display_mismatch(input logic mismatch_found, input integer time, input logic [9:0] in_state, input logic in_d, input logic in_done, input logic in_ack, input logic ref_out, input logic dut_out, string signal_name);
	begin
		if (mismatch_found)
		begin
			if (stats1.errors == 0) stats1.errortime = time;
			stats1.errors++;
			if (signal_name == "B3_next") stats1.errors_B3_next++;
			else if (signal_name == "S_next") stats1.errors_S_next++;
			else if (signal_name == "S1_next") stats1.errors_S1_next++;
			else if (signal_name == "Count_next") stats1.errors_Count_next++;
			else if (signal_name == "Wait_next") stats1.errors_Wait_next++;
			else if (signal_name == "done") stats1.errors_done++;
			else if (signal_name == "counting") stats1.errors_counting++;
			else if (signal_name == "shift_ena") stats1.errors_shift_ena++;
			
			// Record first mismatch time for this specific signal
			if (signal_name == "B3_next") if (stats1.errors_B3_next == 1) stats1.errortime_B3_next = time;
			if (signal_name == "S_next") if (stats1.errors_S_next == 1) stats1.errortime_S_next = time;
			if (signal_name == "S1_next") if (stats1.errors_S1_next == 1) stats1.errortime_S1_next = time;
			if (signal_name == "Count_next") if (stats1.errors_Count_next == 1) stats1.errortime_Count_next = time;
			if (signal_name == "Wait_next") if (stats1.errors_Wait_next == 1) stats1.errortime_Wait_next = time;
			if (signal_name == "done") if (stats1.errors_done == 1) stats1.errortime_done = time;
			if (signal_name == "counting") if (stats1.errors_counting == 1) stats1.errortime_counting = time;
			if (signal_name == "shift_ena") if (stats1.errors_shift_ena == 1) stats1.errortime_shift_ena = time;
		end
	end
	endtask


	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			
			$display("\n--- FIRST MISMATCH DETAILS ---");
			$display("Time of First Mismatch: %0d ps", stats1.errortime);
			$display("Inputs at Mismatch:");
			$display("  d: %b (0x%h)", d, d);
			$display("  done_counting: %b (0x%h)", done_counting, done_counting);
			$display("  ack: %b (0x%h)", ack, ack);
			$display("  state: %b (0x%h)", state, state);
			$display("\nOutputs at Mismatch:");
			$display("  B3_next: REF=%b (0x%h) | DUT=%b (0x%h)", B3_next_ref, B3_next_ref, B3_next_dut, B3_next_dut);
			$display("  S_next: REF=%b (0x%h) | DUT=%b (0x%h)", S_next_ref, S_next_ref, S_next_dut, S_next_dut);
			$display("  S1_next: REF=%b (0x%h) | DUT=%b (0x%h)", S1_next_ref, S1_next_ref, S1_next_dut, S1_next_dut);
			$display("  Count_next: REF=%b (0x%h) | DUT=%b (0x%h)", Count_next_ref, Count_next_ref, Count_next_dut, Count_next_dut);
			$display("  Wait_next: REF=%b (0x%h) | DUT=%b (0x%h)", Wait_next_ref, Wait_next_ref, Wait_next_dut, Wait_next_dut);
			$display("  done: REF=%b (0x%h) | DUT=%b (0x%h)", done_ref, done_ref, done_dut, done_dut);
			$display("  counting: REF=%b (0x%h) | DUT=%b (0x%h)", counting_ref, counting_ref, counting_dut, counting_dut);
			$display("  shift_ena: REF=%b (0x%h) | DUT=%b (0x%h)", shift_ena_ref, shift_ena_ref, shift_ena_dut, shift_ena_dut);
			$display("------------------------------\n");
		end
		
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } === ( { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } ^ { B3_next_dut, S_next_dut, S1_next_dut, Count_next_dut, Wait_next_dut, done_dut, counting_dut, shift_ena_dut } ^ { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Check overall mismatch
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, B3_next_ref, B3_next_dut, "B3_next");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, S_next_ref, S_next_dut, "S_next");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, S1_next_ref, S1_next_dut, "S1_next");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, Count_next_ref, Count_next_dut, "Count_next");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, Wait_next_ref, Wait_next_dut, "Wait_next");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, done_ref, done_dut, "done");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, counting_ref, counting_dut, "counting");
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, shift_ena_ref, shift_ena_dut, "shift_ena");
		end
		
		// Individual error checking (retaining original structure for specific counters)
		if (B3_next_ref !== B3_next_dut) begin 
			if (stats1.errors_B3_next == 0) stats1.errortime_B3_next = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, B3_next_ref, B3_next_dut, "B3_next");
		end
		if (S_next_ref !== S_next_dut) begin 
			if (stats1.errors_S_next == 0) stats1.errortime_S_next = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, S_next_ref, S_next_dut, "S_next");
		end
		if (S1_next_ref !== S1_next_dut) begin 
			if (stats1.errors_S1_next == 0) stats1.errortime_S1_next = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, S1_next_ref, S1_next_dut, "S1_next");
		end
		if (Count_next_ref !== Count_next_dut) begin 
			if (stats1.errors_Count_next == 0) stats1.errortime_Count_next = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, Count_next_ref, Count_next_dut, "Count_next");
		end
		if (Wait_next_ref !== Wait_next_dut) begin 
			if (stats1.errors_Wait_next == 0) stats1.errortime_Wait_next = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, Wait_next_ref, Wait_next_dut, "Wait_next");
		end
		if (done_ref !== done_dut) begin 
			if (stats1.errors_done == 0) stats1.errortime_done = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, done_ref, done_dut, "done");
		end
		if (counting_ref !== counting_dut) begin 
			if (stats1.errors_counting == 0) stats1.errortime_counting = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, counting_ref, counting_dut, "counting");
		end
		if (shift_ena_ref !== shift_ena_dut) begin 
			if (stats1.errors_shift_ena == 0) stats1.errortime_shift_ena = $time;
			s_check_and_display_mismatch(1, $time, state, d, done_counting, ack, shift_ena_ref, shift_ena_dut, "shift_ena");
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule