`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		input tb_match,
		output reg [7:0] in,
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
			in <= 8'b0;
		@(posedge clk);
		wavedrom_start("");
		repeat(2) @(posedge clk);
		in <= 8'b1;
		repeat(4) @(posedge clk);
		in <= 8'b0;
		repeat(4) @(negedge clk);
		in <= 8'h06;
		repeat(2) @(negedge clk);
		in <= 8'b0; 
		repeat(2) @(posedge clk);
		wavedrom_stop();

		repeat(200)
			@(posedge clk, negedge clk) in <= $urandom;
		$finish;
		end
		
endmodule

module tb();

		typedef struct packed {
			int errors;
			int errortime;
			int errors_pedge;
			int errortime_pedge;
			int clocks;
		} stats;
		
		stats stats1;
		
		
		// Signals related to stimulus generator output (from golden testbench)
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		initial forever
			#5 clk = ~clk;
		end

		logic [7:0] in;
		logic [7:0] pedge_ref;
		logic [7:0] pedge_dut;

		// Variables to capture signals at first error time
		logic [7:0] in_at_first_error;
		logic [7:0] pedge_ref_at_first_error;
		logic [7:0] pedge_dut_at_first_error;
		
		initial begin 
			$dumpfile("wave.vcd");
			dumpvars(1, stimulus_gen.clk, tb_match ,clk,in,pedge_ref,pedge_dut );
		end

		wire tb_match;        // Verification
		wire tb_mismatch = ~tb_match;
		
		// Instantiate stimulus generator
		stimulus_gen stim1 (
			.clk(clk),
			.tb_match(tb_match),
			in(in),
			wavedrom_title(wavedrom_title),
			wavedrom_enable(wavedrom_enable));
		
		// Instantiate Reference Module (Assuming RefModule exists)
		RefModule good1 (
			.clk(clk),
			in(in),
			pedge(pedge_ref) );
		
		// Instantiate DUT
		TopModule top_module1 (
			.clk(clk),
			in(in),
			pedge(pedge_dut) );

		
		bit strobe = 0;
		task wait_for_end_of_timestep;
			repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			endtask	

		// --- Display Helper Task (Enhanced for HEX/BIN) ---
		task display_signal(input string signal_name, input logic [7:0] value);
		begin
			$display("
--- First Mismatch Signal Display (Time: %0d ps) ---", $time);
			$display("%s: HEX = %h, BIN = %b", signal_name, value, value);
		endtask

		// --- Error Capture Logic ---
		always @(posedge clk, negedge clk) begin
			stats1.clocks++;
			
			// Check tb_match error
			if (!tb_match) begin
				if (stats1.errors == 0) begin
				stats1.errortime = $time;
				in_at_first_error = in;
				pedge_ref_at_first_error = pedge_ref;
			pedge_dut_at_first_error = pedge_dut;
				$display("
!!! First Mismatch Detected (tb_match) at time %0d ps !!!", $time);
				display_signal("Input (in)", in);
			display_signal("Expected (pedge_ref)", pedge_ref);
			display_signal("Actual (pedge_dut)", pedge_dut);
				stats1.errors++;
				stats1.errortime = $time;
			end
			end
			else begin
				sstats1.errors++;
			end
			end
			
			// Check pedge_ref vs pedge_dut error
			if (pedge_ref !== pedge_dut) 
			begin 
				if (stats1.errors_pedge == 0) begin
				stats1.errortime_pedge = $time;
				end
				// Capture signals specific to this error type if it's the first of its kind
				in_at_first_error = in;
				pedge_ref_at_first_error = pedge_ref;
			pedge_dut_at_first_error = pedge_dut;
				$display("
!!! First Mismatch Detected (pedge) at time %0d ps !!!", $time);
				display_signal("Input (in)", in);
			display_signal("Expected (pedge_ref)", pedge_ref);
			display_signal("Actual (pedge_dut)", pedge_dut);
				stats1.errors_pedge = stats1.errors_pedge + 1'b1;
				stats1.errortime_pedge = $time;
			end
			else begin
				sstats1.errors_pedge = stats1.errors_pedge + 1'b1;
			end
			end
			end

		// Verification check (Must match golden testbench)
		assign tb_match = ( { pedge_ref } === ( { pedge_ref } ^ { pedge_dut } ^ { pedge_ref } ) );
		
		// add timeout after 100K cycles
		initial begin
			#1000000
			$display("TIMEOUT");
			$finish();
		end

		// --- Final Report ---
		initial begin
			#10000000 // Wait a bit longer than timeout to ensure simulation has run its course or timeout
			
			if (stats1.errors == 0 && stats1.errors_pedge == 0)
				$display("
=======================================");
				$display("SIMULATION PASSED");
				$display("=======================================");
			else begin
				int total_errors = stats1.errors + stats1.errors_pedge;
				int first_error_time = 9999999999; // Initialize to a very large time
			
			// Determine the absolute first error time
			if (stats1.errors > 0) first_error_time = (stats1.errortime < first_error_time) ? stats1.errortime : first_error_time;
			if (stats1.errors_pedge > 0) first_error_time = (stats1.errortime_pedge < first_error_time) ? stats1.errortime_pedge : first_error_time;
			
			$display("
=======================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_errors, first_error_time);
			$display("=======================================");
			end
			$finish;
		end

endmodule
