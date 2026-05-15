`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg reset
);

	initial begin
		repeat(100) @(negedge clk) begin
			reset <= !($random & 31);
		end;

		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
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

	logic reset;
	logic shift_ena_ref;
	logic shift_ena_dut;

	// Queue for mismatch display
	logic clk_q [$];
	logic reset_q [$];
	logic shift_ena_ref_q [$];
	logic shift_ena_dut_q [$];
	localparam MAX_QUEUE_SIZE = 10;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,shift_ena_ref,shift_ena_dut );
	end

	wire tb_match;    // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.reset );
	RefModule good1 (
		.clk,
		.reset,
		.shift_ena(shift_ena_ref) );
		
	TopModule top_module1 (
		.clk,
		.reset,
		.shift_ena(shift_ena_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { shift_ena_ref } === ( { shift_ena_ref } ^ { shift_ena_dut } ^ { shift_ena_ref } ) );

	// Mismatch detection and queue management
	always @(posedge clk, negedge clk) begin

		// Maintain queue size
		if (clk_q.size() >= MAX_QUEUE_SIZE) begin
			clk_q.delete(0);
			reset_q.delete(0);
			shift_ena_ref_q.delete(0);
			shift_ena_dut_q.delete(0);
		end

		// Push current values
		clk_q.push_back(clk);
		reset_q.push_back(reset);
		shift_ena_ref_q.push_back(shift_ena_ref);
		shift_ena_dut_q.push_back(shift_ena_dut);

		stats1.clocks++;

		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;

			// Display queue on first mismatch
			if (stats1.errors == 1) begin
				$display("Mismatch detected at time %t", $time);
				$display("\nFirst mismatch history (last %0d cycles):", clk_q.size());
				for (int i = 0; i < clk_q.size(); i++) begin
					$display("Cycle %0d: reset=%b, clk=%b, ref=%b, dut=%b", 
								i, reset_q[i], clk_q[i], shift_ena_ref_q[i], shift_ena_dut_q[i]);
					end;
			end
		end

		if (shift_ena_ref !== ( shift_ena_ref ^ shift_ena_dut ^ shift_ena_ref )) begin 
			if (stats1.errors_shift_ena == 0) stats1.errortime_shift_ena = $time;
			stats1.errors_shift_ena = stats1.errors_shift_ena + 1'b1; 
		end
	end

	// add timeout after 100K cycles
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

		if (stats1.errors_shift_ena) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "shift_ena", stats1.errors_shift_ena, stats1.errortime_shift_ena);
		else $display("Hint: Output '%s' has no mismatches.", "shift_ena");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule