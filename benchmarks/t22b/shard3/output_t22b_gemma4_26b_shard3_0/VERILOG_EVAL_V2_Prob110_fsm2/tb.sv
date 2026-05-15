`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic j, k,
	output logic areset,
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

	reg [0:11][1:0] d = 24'b000101010010101111111111;
	
	initial begin
		reset <= 1;
		j <= 0;
		k <= 0;
		@(posedge clk);
		reset <= 0;
		j <= 1;
		@(posedge clk);
		j <= 0;
		wavedrom_start("Reset and transitions");
		reset_test(1);
		for (int i=0;i<12;i++) begin
			@(posedge clk) {k, j} <= d[i];
		end
		wavedrom_stop();
		repeat(200) begin
			@(posedge clk, negedge clk);
			{j,k} <= $random;
			reset <= !($random & 7);
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
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic j;
	logic k;
	logic areset;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_match, clk, j, k, areset, out_ref, out_dut);
	end

	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.*,
		.j,
		.k,
		.areset 
	);

	RefModule good1 (
		.clk,
		.j,
		.k,
		.areset,
		.out(out_ref) 
	);
		
	TopModule top_module1 (
		.clk,
		.j,
		.k,
		.areset,
		.out(out_dut) 
	);

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;
			@(strobe);
		end
	endtask	

	final begin
		if (stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
			$display("Hint: Output 'out' has no mismatches.");
		end
		if (stats1.errors_out > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			$display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		end

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
	end
	
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end

		if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
			if (stats1.errors_out == 0) begin
				stats1.errortime_out = $time;
				$display("Mismatch detected at %0t ps:", $time);
				$display("  Inputs: j=%b, k=%b, areset=%b, clk=%b", j, k, areset, clk);
				$display("  Outputs: Expected out=%b, Actual out=%b", out_ref, out_dut);
			end
			stats1.errors_out = stats1.errors_out + 1'b1;
		end
	end

	initial begin
		#1000000;
		$display("TIMEOUT");
		$finish();
	end

endmodule