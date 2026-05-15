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

	logic d;
	logic ar;
	logic q_ref;
	logic q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,d,ar,q_ref,q_dut );
	end

	wire tb_match; // Verification
	wire tb_mismatch = ~tb_match;
	stimulus_gen stim1 (
		.clk,
		.d(d),
		.ar(ar)
	);
	TopModule top_module1 (
		.clk,
		.d(d),
		.ar(ar),
		.q(q_dut)
	);

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask

	final begin
		if (stats1.errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", stats1.errors_q, stats1.errortime_q);
		else $display("SIMULATION PASSED");
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0t ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			stats1.errors_q++;
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end
endmodule