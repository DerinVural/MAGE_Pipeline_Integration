`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg a, b, c, d,
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
		int count; count = 0;
		{a,b,c,d} <= 4'b0;
		wavedrom_start();
		repeat(16) @(posedge clk)
			{a,b,c,d} <= count++;
		@(negedge clk) wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{d,c,b,a} <= $urandom;
		
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
		h#5 clk = ~clk;


	logic a;
	logic b;
	logic c;
	logic d;
	logic out_ref;
	logic out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,out_ref,out_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		a,
		b,
		c,
		d );
	RefModule good1 (
		a,
		b,
		c,
		d,
		.out(out_ref) );
	
	TopModule top_module1 (
		a,
		b,
		c,
		d,
		out_dut );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task
	
	// Function to display signals in HEX and BINARY format
	function display_signal(logic sig, string label, integer index);
		// For 1-bit signals, %h and %b are sufficient.
		$display("[%s] Time %0t: Value = %h (Binary: %b)", label, $time, sig, sig);
	endfunction

	// Function to display the first mismatch details
	function display_mismatch_details(integer err_time);
		$display("========================================================", 1);
		$display("*** FIRST MISMATCH DETECTED ***", 1);
		$display("Time of first mismatch: %0d ps", err_time);
		$display("--------------------------------------------------------", 1);
		$display("Inputs:", 1);
		display_signal(a, "a", 0);
		display_signal(b, "b", 1);
		display_signal(c, "c", 2);
		display_signal(d, "d", 3);
		$display("Outputs:", 1);
		display_signal(out_dut, "DUT Output (out)", 4);
		display_signal(out_ref, "Reference Output (out_ref)", 5);
		$display("========================================================", 1);
	endfunction

	// Helper task to call display_mismatch_details correctly
	task send_mismatch_details_at_time(integer t);
		display_mismatch_details(t);
	endtask

	
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end
		else begin
			integer total_mismatches = stats1.errors;
			integer first_mismatch_time = stats1.errortime;
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_mismatch_time);
			
			if (total_mismatches > 0 && stats1.errortime != 0) begin
				send_mismatch_details_at_time(stats1.errortime);
			end
		end
		end
	
	// Verification: tb_match is true if out_ref == out_dut
	assign tb_match = ( out_ref === out_dut );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			
			if (stats1.errors == 0) begin
				// Capture details when errors count is about to increment from 0 to 1
				send_mismatch_details_at_time($time);
			end
			sstats1.errors++;
		end
		
		// Logic for errors_out (maintained from golden TB structure)
		if (out_ref !== out_dut) 
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
		end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule