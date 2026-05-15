`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	input tb_match,
	output logic [7:0] in,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		in <= 0;
		@(posedge clk);
		@(negedge clk) wavedrom_start("");
		repeat(2) @(posedge clk);
		in <= 1;
		repeat(4) @(posedge clk);
		in <= 0;
		repeat(4) @(negedge clk);
		in <= 6;
		repeat(2) @(negedge clk);
		in <= 0;
		repeat(2) @(posedge clk);
		@(negedge clk) wavedrom_stop();
			
		repeat(200)
			@(posedge clk, negedge clk) in <= $random;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_anyedge;
		int errortime_anyedge;

		int clocks;
	} stats;
	
	stats stats1;
	
		
	logic [511:0] wavedrom_title;
	logic wavedrom_enable;
	int wavedrom_hide_after_time;
	
	logic clk=0;
	initial forever
		#5 clk = ~clk;

	logic [7:0] in;
	logic [7:0] anyedge_ref;
	logic [7:0] anyedge_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, clk, in, anyedge_ref, anyedge_dut);
	end

	wire tb_match; // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.*,
		.in
	);

	RefModule good1 (
		.clk,
		.in,
		.anyedge(anyedge_ref)
	);
		
	TopModule top_module1 (
		.clk,
		.in,
		.anyedge(anyedge_dut)
	);

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	

	assign tb_match = ( { anyedge_ref } === ( { anyedge_ref } ^ { anyedge_dut } ^ { anyedge_ref } ) );

	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (anyedge_ref !== ( anyedge_ref ^ anyedge_dut ^ anyedge_ref ))
		begin 
			if (stats1.errors_anyedge == 0) stats1.errortime_anyedge = $time;
			stats1.errors_anyedge = stats1.errors_anyedge + 1'b1; 
		end
	end

	// Handle First Mismatch Display
	always @(posedge clk, negedge clk) begin
		if (!tb_match && stats1.errors == 1 && stats1.errortime == $time) begin
			$display("FIRST MISMATCH DETECTED at time %0t:", $time);
			$display("  in:          %h (%b)", in, in);
			$display("  anyedge_ref: %h (%b)", anyedge_ref, anyedge_ref);
			$display("  anyedge_dut: %h (%b)", anyedge_dut, anyedge_dut);
		end
	end

	// Timeout logic
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	final begin
		if (stats1.errors > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			if (stats1.errors_anyedge) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "anyedge", stats1.errors_anyedge, stats1.errortime_anyedge);
			else $display("Hint: Output '%s' has no mismatches.", "anyedge");
			$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		end else begin
			$display("SIMULATION PASSED");
			if (stats1.errors_anyedge) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "anyedge", stats1.errors_anyedge, stats1.errortime_anyedge);
			else $display("Hint: Output '%s' has no mismatches.", "anyedge");
			$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		end
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule