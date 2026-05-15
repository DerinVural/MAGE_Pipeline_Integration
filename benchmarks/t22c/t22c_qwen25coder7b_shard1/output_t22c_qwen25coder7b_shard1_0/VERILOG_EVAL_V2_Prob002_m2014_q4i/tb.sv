module stimulus_gen (
	input clk
);
	random [31:0] num;

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			if (num > 50)
				out = 1;
			else
				out = 0;
		end

		#1 $finish;
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
	wire clk=0;
	logic out_ref;
	logic out_dut;
	initial forever
		#5 clk = ~clk;
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,out_ref,out_dut );
	end
	signal tb_match;	 signal tb_mismatch = ~tb_match;
	stimulus_gen stim1 (
		.clk,
	);
	RefModule good1 (
		.out(out_ref)
	);
	TopModule top_module1 (
		.out(out_dut)
	);
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask
	final begin
		if (stats1.errors_out) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
		else $display("SIMULATION PASSED");
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatch: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out + 1'b1; end
	end
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
endmodule