`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- stimulus_gen (Kept mostly as is, as it's external stimulus) ---
module stimulus_gen (
	input clk,
	output reg reset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
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
		s
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask
	
	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable
		task wavedrom_start(input[511:0] title = "");
	endtask
	task wavedrom_stop;
		#1;
	endtask
		
		
		initial begin
			reset <= 1;
			wavedrom_start("Synchronous reset");
			reset_test();
			repeat(5) @(posedge clk);
			wavedrom_stop();
			
			reset <= 0;
			repeat(989) @(negedge clk);
			wavedrom_start("Wrap around behaviour");
			repeat(14)@(posedge clk);
			wavedrom_stop();
			
			
			repeat(2000) @(posedge clk, negedge clk) begin
				reset <= !($random & 127);
			end
			reset <= 0;
			repeat(2000) @(posedge clk);
			
			#1 $finish;
		end
	endmodule

// --- DUT Implementation (TopModule) ---
module TopModule(
    input logic clk,
    input logic reset,
    output logic [9:0] q
);
    // Internal register to hold the counter state
    logic [9:0] count_reg;

    // Sequential logic for the counter
    always @(posedge clk)
    begin
        if (reset)
        begin
            // Synchronous reset to 0
            count_reg <= 10'd0;
        end
        else begin
            // Counter logic: Count from 0 to 999.
            // If current count is 999, next count is 0 (wraps around).
            if (count_reg == 10'd999)
            begin
                count_reg <= 10'd0;
            end
            else
            begin
                // Increment the counter
                count_reg <= count_reg + 1;
            end
        end
    end

    // Assign the internal register to the output port
    assign q = count_reg;

endmodule

// --- Testbench ---
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
		h#5 clk = ~clk;

	logic reset;
	logic [9:0] q_ref;
	logic [9:0] q_dut;

	// Variables to track first mismatch details
	int first_mismatch_time = -1;
	logic [9:0] first_q_ref_at_mismatch = 10'h0;
	logic [9:0] first_q_dut_at_mismatch = 10'h0;
	logic first_error_detected = 0;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen, clk, reset, q_ref, q_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus_gen (Matching golden TB structure)
	stimulus_gen stim1 (
		.clk, 
		.reset, 
		wavedrom_title, 
		wavedrom_enable, 
		.tb_match
	);
	
	// Instantiate Reference Module (Assuming RefModule exists)
	RefModule good1 (
		.clk, 
		.reset, 
		.q(q_ref) );
	
	// Instantiate DUT
	TopModule top_module1 (
		.clk,
		.reset,
		.q(q_dut) );
	
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	// Helper function for formatted display
	task display_signals(input real current_time);
		begin
			$display("
====================================================");
			$display("*** FIRST MISMATCH DETECTED ***");
			$display("Time: %0t ps", current_time);
			$display("----------------------------------------------------");
			$display("INPUTS:");
			$display("  clk: %b", clk);
			$display("  reset: %b", reset);
			$display("OUTPUTS:");
			// Displaying 10-bit signals in HEX and BINARY
			$display("  DUT q: %h (Binary: %b)", q_dut, q_dut);
			$display("  REF q: %h (Binary: %b)", q_ref, q_ref);
			$display("====================================================");
		endtask
	
	
	initial begin
		stats1 = {0, 0, 0, 0, 0};
		
		// Initialize signals
		reset = 1;
		
		// Start stimulus generation
		stimulus_gen::wavedrom_start("Synchronous reset");
		
		// Wait for reset to settle before starting comparison logic
		@(posedge clk);
	end

	// Verification: Direct comparison based on the functional requirement.
	assign tb_match = ( { q_ref } === { q_dut } ); 
	
	// Clock and Verification Loop
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// 1. Check general match (Original error counting)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++; 
			end
		
		// 2. Check specific Q mismatch (Original errors_q counting)
		if (q_ref !== q_dut) 
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q + 1'b1; 
		end
		
		// 3. Track FIRST mismatch for detailed logging
		if (!tb_match && first_error_detected == 0) begin
			first_error_detected = 1;
			first_mismatch_time = $time;
			first_q_ref_at_mismatch = q_ref;
			first_q_dut_at_mismatch = q_dut;
			// Display detailed information at the FIRST mismatch
			display_signals($time);
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("
**********************************");
		$display("TIMEOUT REACHED: %0t ps", $time);
		$display("**********************************");
		$finish();
	end

	// FINAL CHECK AND REPORTING
	initial begin
		// Wait for simulation to stabilize after activity
		@(negedge clk);
		#10; // Small delay for final logic propagation
		
		if (stats1.errors == 0 && stats1.errors_q == 0) begin
			$display("
=========================================");
			$display("SIMULATION PASSED");
			$display("=========================================");
			end
		else begin
			$display("
=========================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_mismatch_time);
			$display("=========================================");
			end
		$finish;
	end
	endmodule