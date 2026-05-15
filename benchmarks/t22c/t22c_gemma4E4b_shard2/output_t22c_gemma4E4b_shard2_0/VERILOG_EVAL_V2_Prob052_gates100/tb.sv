`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	input tb_match,
	output logic [99:0] in,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	
	
	initial begin
		reg [3:0] count; count = 0;
		in <= 100'h0;
		// AND gate uses huge numbers and creates a sparse waveform.
		@(negedge clk) wavedrom_start("Test AND gate");
			@(posedge clk,negedge clk) in <= 100'h0; // Test OR gate
			@(posedge clk,negedge clk); in <= ~100'h0; // Test AND gate
			@(posedge clk,negedge clk); in <= 100'h3ffff;
			@(posedge clk,negedge clk); in <= ~100'h3ffff;
			@(posedge clk,negedge clk); in <= 100'h80;
			@(posedge clk,negedge clk); in <= ~100'h80;
		wavedrom_stop();

		@(negedge clk) wavedrom_start("Test OR and XOR gates");
			@(posedge clk) in <= 100'h0; // Test OR gate
			@(posedge clk); in <= 100'h7; // Test AND gate
			repeat(10) @(posedge clk, negedge clk) begin
			in <= count;
			count <= count + 1;
		end
			@(posedge clk) in <= 100'h0;
		wavedrom_stop();
		
in <= $random;
		repeat(100) begin
		@(negedge clk) in <= $random;
		@(posedge clk) in <= $random;
		end
		for (int i=0;i<100;i++) begin
			@(negedge clk) in <= 100'h1<<i;
			@(posedge clk) in <= ~(100'h1<<i);
		end
		@(posedge clk) in <= 100'h0; // Test OR gate
		@(posedge clk); in <= ~100'h0; // Test AND gate
		@(posedge clk);
		#1 $finish;
	end	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_and;
		int errortime_out_and;
		int errors_out_or;
		int errortime_out_or;
		int errors_out_xor;
		int errortime_out_xor;
		int clocks;
		// Variables to store state at first mismatch
		logic [99:0] first_in;
		logic first_out_and_dut, first_out_or_dut, first_out_xor_dut;
		logic first_out_and_ref, first_out_or_ref, first_out_xor_ref;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [99:0] in;
	logic out_and_ref;
	logic out_and_dut;
	logic out_or_ref;
	logic out_or_dut;
	logic out_xor_ref;
	logic out_xor_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_match ,in,out_and_ref,out_and_dut,out_or_ref,out_or_dut,out_xor_ref,out_xor_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	RefModule good1 (
		in,
		out_and(out_and_ref),
		out_or(out_or_ref),
		out_xor(out_xor_ref) );
	
	TopModule top_module1 (
		in,
		out_and(out_and_dut),
		out_or(out_or_dut),
		out_xor(out_xor_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
	// Helper function to display signals in required format
	task display_mismatch_details;
		$display("
======================================================================");
		$display("--- FIRST MISMATCH DETECTED AT TIME %0d ps ---", $time);
		// Display Input Signals (100 bits)
		$display("Input Signals (in): HEX = %h, BIN = %b", first_in, first_in);
		// Display Reference Outputs (1 bit)
		$display("Reference Outputs: AND = %b, OR = %b, XOR = %b", first_out_and_ref, first_out_or_ref, first_out_xor_ref);
		// Display DUT Outputs (1 bit)
		$display("DUT Outputs:       AND = %b, OR = %b, XOR = %b", first_out_and_dut, first_out_or_dut, first_out_xor_dut);
		$display("======================================================================");
	endtask
	
	initial begin
		// Initialize tracking variables
		stats1.errors = 0;
		stats1.errortime = 0;
		stats1.errors_out_and = 0;
		stats1.errortime_out_and = 0;
		stats1.errors_out_or = 0;
		stats1.errortime_out_or = 0;
		stats1.errors_out_xor = 0;
		stats1.errortime_out_xor = 0;
		stats1.clocks = 0;
	end
	
	// Verification check
	assign tb_match = ( { out_and_ref, out_or_ref, out_xor_ref } === ( { out_and_ref, out_or_ref, out_xor_ref } ^ { out_and_dut, out_or_dut, out_xor_dut } ^ { out_and_ref, out_or_ref, out_xor_ref } ) );
		// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture signals at first error
				first_in = in;
				out_and_dut = out_and_dut;
				out_or_dut = out_or_dut;
				out_xor_dut = out_xor_dut;
				first_out_and_ref = out_and_ref;
				out_or_ref = out_or_ref;
				out_xor_ref = out_xor_ref;
			display_mismatch_details();
			end
			stats1.errors++;
		end
		
		// Mismatch specific checks (must follow original logic)
		if (out_and_ref !== ( out_and_ref ^ out_and_dut ^ out_and_ref ))
		begin if (stats1.errors_out_and == 0) stats1.errortime_out_and = $time;
			sstats1.errors_out_and = stats1.errors_out_and+1'b1; end
		
		if (out_or_ref !== ( out_or_ref ^ out_or_dut ^ out_or_ref ))
		begin if (stats1.errors_out_or == 0) stats1.errortime_out_or = $time;
			sstats1.errors_out_or = stats1.errors_out_or+1'b1; end
		
		if (out_xor_ref !== ( out_xor_ref ^ out_xor_dut ^ out_xor_ref ))
		begin if (stats1.errors_out_xor == 0) stats1.errortime_out_xor = $time;
			sstats1.errors_out_xor = stats1.errors_out_xor+1'b1; end
		end
		
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final Summary Display
	initial begin
		// Wait for simulation to settle or reach the end condition
		@(negedge clk);
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
		$finish();
	end

endmodule
