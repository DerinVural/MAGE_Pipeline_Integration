`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg reset,
	output reg data, done_counting, ack,
	input tb_match
);
	bit failed = 0;
	
always @(posedge clk, negedge clk)
		if (!tb_match) 
		if (failed) 
			failed <= 1;
		else 
			failed <= 0;
	
	initial begin

		@(posedge clk);
		failed <= 0;
		reset <= 1;
		data <= 0;
		done_counting <= 1'bx;
		ack <= 1'bx;
		@(posedge clk) 
			data <= 1;
			reset <= 0;
		@(posedge clk) data <= 0;
		@(posedge clk) data <= 0;
		@(posedge clk) data <= 1;
		@(posedge clk) data <= 1;
		@(posedge clk) data <= 0;
		@(posedge clk) data <= 1;
		@(posedge clk);
			data <= 1'bx;
		repeat(4) @(posedge clk);
		done_counting <= 1'b0;
		repeat(4) @(posedge clk);
		done_counting <= 1'b1;
		@(posedge clk);
		done_counting <= 1'bx;
		ack <= 1'b0;
		repeat(3) @(posedge clk);
		ack <= 1'b1;
		@(posedge clk);
		ack <= 1'b0;
		data <= 1'b1;
		@(posedge clk);
		ack <= 1'bx;
		data <= 1'b1;
		@(posedge clk);
		data <= 1'b0;
		@(posedge clk);
		data <= 1'b1;
		@(posedge clk);
		data <= 1'bx;
		repeat(4) @(posedge clk);
		done_counting <= 1'b0;
		repeat(4) @(posedge clk);
		done_counting <= 1'b1;
		@(posedge clk);

	if (failed)
		s$display("Hint: Your FSM didn't pass the sample timing diagram posted with the problem statement. Perhaps try debugging that?");
		
		repeat(5000) @(posedge clk, negedge clk) begin
			reset <= !($random & 255);
			data <= $random;
		done_counting <= !($random & 31);
		ack <= !($random & 31);
		end
		
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_shift_ena;
		int errortime_shift_ena;
		int errors_counting;
		int errortime_counting;
		int errors_done;
		int errortime_done;
		int clocks;
		int mismatch_time;
		logic [7:0] inputs_at_mismatch;
		logic [7:0] dut_outputs_at_mismatch;
		logic [7:0] ref_outputs_at_mismatch;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic reset;
	logic data;
	logic done_counting;
	logic ack;
	logic shift_ena_ref;
	logic shift_ena_dut;
	logic counting_ref;
	logic counting_dut;
	logic done_ref;
	logic done_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen.clk, tb_mismatch ,clk,reset,data,done_counting,ack,shift_ena_ref,shift_ena_dut,counting_ref,counting_dut,done_ref,done_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.reset, 
		.data, 
		done_counting, 
		.ack, 
		tb_match
	);
	RefModule good1 (
		.clk, 
		.reset, 
		.data, 
		done_counting, 
		.ack, 
		.shift_ena(shift_ena_ref), 
		.counting(counting_ref), 
		done(done_ref) );
	TopModule top_module1 (
		.clk, 
		.reset, 
		.data, 
		done_counting, 
		.ack, 
		.shift_ena(shift_ena_dut), 
		.counting(counting_dut), 
		done(done_dut) );

	
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
		
			// Display detailed mismatch information
			$display("===============================================================");
			$display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
			$display("Inputs:");
			$display("  clk: %b (Hex: %h)", inputs_snap[0], inputs_snap[0]);
			$display("  reset: %b (Hex: %h)", inputs_snap[1], inputs_snap[1]);
			$display("  data: %b (Hex: %h)", inputs_snap[2], inputs_snap[2]);
			$display("  done_counting: %b (Hex: %h)", inputs_snap[3], inputs_snap[3]);
			$display("  ack: %b (Hex: %h)", inputs_snap[4], inputs_snap[4]);
			$display("Outputs (DUT vs Expected): ");
			$display("  shift_ena: DUT=%b (Hex: %h) | Expected=%b (Hex: %h)", dut_snap[0], dut_snap[0], ref_snap[0], ref_snap[0]);
			$display("  counting: DUT=%b (Hex: %h) | Expected=%b (Hex: %h)", dut_snap[1], dut_snap[1], ref_snap[1], ref_snap[1]);
			$display("  done: DUT=%b (Hex: %h) | Expected=%b (Hex: %h)", dut_snap[2], dut_snap[2], ref_snap[2], ref_snap[2]);
			$display("===============================================================");
		end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { shift_ena_ref, counting_ref, done_ref } === ( { shift_ena_ref, counting_ref, done_ref } ^ { shift_ena_dut, counting_dut, done_dut } ^ { shift_ena_ref, counting_ref, done_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		// Capture current state for potential error reporting
		inputs_snap[0] <= clk;
		inputs_snap[1] <= reset;
		inputs_snap[2] <= data;
		inputs_snap[3] <= done_counting;
		inputs_snap[4] <= ack;
		dut_snap[0] <= shift_ena_dut;
		dut_snap[1] <= counting_dut;
		dut_snap[2] <= done_dut;
		ref_snap[0] <= shift_ena_ref;
		ref_snap[1] <= counting_ref;
		ref_snap[2] <= done_ref;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.mismatch_time = $time;
			// Capture inputs and outputs at the mismatch time
			inputs_snap <= {clk, reset, data, done_counting, ack, 5'b0};
		dut_snap <= {shift_ena_dut, counting_dut, done_dut, 5'b0};
		ref_snap <= {shift_ena_ref, counting_ref, done_ref, 5'b0};
		stats1.errors++;
		end
		
		// Original error counting logic must be maintained
		if (shift_ena_ref !== ( shift_ena_ref ^ shift_ena_dut ^ shift_ena_ref ))
			begin if (stats1.errors_shift_ena == 0) stats1.errortime_shift_ena = $time;
			sstats1.errors_shift_ena = stats1.errors_shift_ena+1'b1; end
		
		if (counting_ref !== ( counting_ref ^ counting_dut ^ counting_ref ))
			begin if (stats1.errors_counting == 0) stats1.errortime_counting = $time;
			sstats1.errors_counting = stats1.errors_counting+1'b1; end
		
		if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
			begin if (stats1.errors_done == 0) stats1.errortime_done = $time;
			sstats1.errors_done = stats1.errors_done+1'b1; end
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule