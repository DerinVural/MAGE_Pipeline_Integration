`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [31:0] in,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		h#1;
	endtask	

	initial begin
		wavedrom_start("Random inputs");
		repeat(10) @(posedge clk, negedge clk) 
		in <= $random;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
		in <= $random;
		$finish;
	end

dendmodule

module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	
// Signals from stimulus_gen (must be declared as wires/regs based on stimulus_gen definition)
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	// Clock generation
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	// DUT/Reference signals
	logic [31:0] in;
	logic [31:0] out_ref;
	logic [31:0] out_dut;

	// Signals to capture state on first mismatch
	logic [31:0] capture_in;
	logic [31:0] capture_out_dut;
	logic [31:0] capture_out_ref;

	initial begin 
		$dumpfile("wave.vcd");
		// Dump all relevant signals
		$dumpvars(1, stim1.clk, tb_mismatch, in, out_ref, out_dut, wavedrom_title, wavedrom_enable);
	end
	
	// Verification signals
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiations
	stimulus_gen stim1 (
		.clk, clk,
		in, in,
		wavedrom_title, wavedrom_title,
		wavedrom_enable, wavedrom_enable
	);
		
	// Assuming RefModule is defined elsewhere to provide the expected output
	RefModule good1 (
		.in, in,
		out(out_ref) 
	);
		
	TopModule top_module1 (
		.in, in,
		out(out_dut) 
	);

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end	task
	
	
	final begin
		if (stats1.errors == 0 && stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
		end
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		end
		
		if (stats1.errors > 0 || stats1.errors_out > 0) begin
			// Determine the time of the first total mismatch, prioritizing total error time if both occurred
			int failure_time = (stats1.errors > 0) ? stats1.errortime : stats1.errortime_out;
			int total_mismatches = stats1.errors; // Use total error count as the primary count for failure message
			
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, failure_time);
			
			// Detailed display for total mismatch
			if (stats1.errors > 0) begin
				$display("\n--- First Total Mismatch Details (Time: %0d) ---", stats1.errortime);
				$display("Input (in):  HEX=%h, BIN=%b", capture_in, capture_in);
				$display("Expected (out_ref): HEX=%h, BIN=%b", capture_out_ref, capture_out_ref);
				$display("Actual (out_dut): HEX=%h, BIN=%b", capture_out_dut, capture_out_dut);
				end
			
			// Detailed display for output mismatch
			if (stats1.errors_out > 0) begin
				$display("\n--- First Output Mismatch Details (Time: %0d) ---", stats1.errortime_out);
				$display("Input (in):  HEX=%h, BIN=%b", capture_in, capture_in);
				$display("Expected (out_ref): HEX=%h, BIN=%b", capture_out_ref, capture_out_ref);
				$display("Actual (out_dut): HEX=%h, BIN=%b", capture_out_dut, capture_out_dut);
			end
			
			$display("Total Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
		end
		
		$finish;
		end
	
	// Verification: out_ref === out_dut
	assign tb_match = ( out_ref === out_dut ); 
	
	// Logic to capture state upon first mismatch and count errors
	always @(posedge clk, negedge clk) begin
		
		// Default capture to current state
		capture_in <= in;
		capture_out_dut <= out_dut;
		capture_out_ref <= out_ref;
		
		stats1.clocks++;
		
		// Check Total Mismatch Error
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				sstats1.errortime = $time;
				// Capture state on first total error
				capture_in <= in;
				capture_out_dut <= out_dut;
				capture_out_ref <= out_ref;
			end
			stats1.errors++;
		end
		
		// Check Output Mismatch Error
		if (out_ref !== out_dut) 
		begin 
			if (stats1.errors_out == 0) begin
				sstats1.errortime_out = $time;
				// Capture state on first output error
				capture_in <= in;
				capture_out_dut <= out_dut;
				capture_out_ref <= out_ref;
			end
			stats1.errors_out = stats1.errors_out + 1'b1;
		end
		end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule