`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg [2:0] y,
	output reg w
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{y,w} <= $random;
		end;
		
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_Y1;
		int errortime_Y1;

		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [2:0] y;
	logic w;
	logic Y1_ref;
	logic Y1_dut;

	// Queues for mismatch display
	logic [2:0] y_q [$];
	logic w_q [$];
	logic Y1_ref_q [$];
	logic Y1_dut_q [$];
	localparam MAX_QUEUE_SIZE = 10;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,y,w,Y1_ref,Y1_dut );
	end

	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.y,
		.w );
	RefModule good1 (
		.y,
		.w,
		.Y1(Y1_ref) );
		
	TopModule top_module1 (
		.y,
		.w,
		.Y1(Y1_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	

	final begin
		if (stats1.errors == 0 && stats1.errors_Y1 == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end

		if (stats1.errors_Y1) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Y1", stats1.errors_Y1, stats1.errortime_Y1);
		else $display("Hint: Output '%s' has no mismatches.", "Y1");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { Y1_ref } === ( { Y1_ref } ^ { Y1_dut } ^ { Y1_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;

		// Push to queues
		if (y_q.size() >= MAX_QUEUE_SIZE) begin
			y_q.delete(0);
			w_q.delete(0);
			Y1_ref_q.delete(0);
			Y1_dut_q.delete(0);
		end
		y_q.push_back(y);
		w_q.push_back(w);
		Y1_ref_q.push_back(Y1_ref);
		Y1_dut_q.push_back(Y1_dut);

		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
			if (stats1.errors == 1) begin
				$display("Mismatch detected at time %t", $time);
				$display("\nLast %d cycles of simulation:", y_q.size());
				for (int i = 0; i < y_q.size(); i++) begin
					$display("Cycle %d, y=%b(%h), w=%b, Y1_ref=%b, Y1_dut=%b", 
							i, y_q[i], y_q[i], w_q[i], Y1_ref_q[i], Y1_dut_q[i]);
				end
			end
		end

		if (Y1_ref !== ( Y1_ref ^ Y1_dut ^ Y1_ref )) begin 
			if (stats1.errors_Y1 == 0) stats1.errortime_Y1 = $time;
			stats1.errors_Y1 = stats1.errors_Y1 + 1'b1; 
		end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule