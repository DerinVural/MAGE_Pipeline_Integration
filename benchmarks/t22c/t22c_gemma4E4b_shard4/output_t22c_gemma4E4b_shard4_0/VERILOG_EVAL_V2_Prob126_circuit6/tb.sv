`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// --- Stimulus Generation Module (Preserved from Golden Testbench) ---
module stimulus_gen (
	input clk,
	output logic [2:0] a,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
task wavedrom_stop;
		h#1;
	endtask

	initial begin
		@(negedge clk) wavedrom_start("Unknown circuit");
		@(posedge clk) {a} <= 3'b0;
		repeat(10) @(posedge clk,negedge clk) a <= a + 1;
		wavedrom_stop();

		repeat(100) @(posedge clk, negedge clk)
		a <= $urandom;
		$finish;
	end
	endmodule


// --- Reference Module (Implemented with correct logic derived from spec) ---
module RefModule (
    input logic [2:0] a,
    output logic [15:0] q
);
    // This module implements the expected reference values derived from the spec table
    always_comb begin
        case (a)
            3'd0: q = 16'h1232; // 1232
            3'd1: q = 16'haee0; // aee0
            3'd2: q = 16'h27d4; // 27d4
            3'd3: q = 16'h5a0e; // 5a0e
            3'd4: q = 16'h2066; // 2066
            3'd5: q = 16'h64ce; // 64ce
            3'd6: q = 16'hc526; // c526
            3'd7: q = 16'h2f19; // 2f19
            default: q = 16'h0000;
        endcase
    end
endmodule


// --- DUT Module Implementation (TopModule - Matches Input Spec) ---
module TopModule (
    input  logic [2:0] a,
    output logic [15:0] q
);

    // Combinational logic implemented via case statement based on input table
    always_comb begin
        case (a)
            3'd0: q = 16'h1232; // 1232
            3'd1: q = 16'haee0; // aee0
            3'd2: q = 16'h27d4; // 27d4
            3'd3: q = 16'h5a0e; // 5a0e
            3'd4: q = 16'h2066; // 2066
            3'd5: q = 16'h64ce; // 64ce
            3'd6: q = 16'hc526; // c526
            3'd7: q = 16'h2f19; // 2f19
            default: q = 16'h0000; // Default case
        endcase
    end
endmodule


// --- Testbench (Improved) ---
module tb();
	
	type struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
	}
	
	stats stats1;
	
	// Signals from stimulus_gen
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	// Signals being tested
	logic [2:0] a;
	logic [15:0] q_ref;
	logic [15:0] q_dut;

	// Tracking variables for first mismatch logging
	integer first_mismatch_time = -1;
	logic [2:0] first_mismatch_a = 0;
	logic [15:0] first_mismatch_q_ref = 0;
	logic [15:0] first_mismatch_q_dut = 0;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen::stim1, tb_mismatch, a, q_ref, q_dut );
	end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk, 
		a, 
		wavedrom_title, 
		wavedrom_enable
);
	
RefModule good1 (
		a, 
		.q(q_ref) );
	
TopModule top_module1 (
		a, 
		.q(q_dut) );
	
	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
	
// Helper task for display formatting
task display_signal;
		input string name;
		input logic [15:0] value;
		input logic [2:0] val_a;
		
		$display("\n==============================================\n");
		$display("--- Mismatch Details at Time %0d ps ---", $time);
		$display("Signal: %s", name);
		
		// Display A
		$display("  Input A (Dec): %0d | (Bin): %b", val_a, val_a);
		// Display DUT Q
		$display("  DUT Q (Hex): 0x%h | (Bin): %b", value, value);
		// Display REF Q
		$display("  REF Q (Hex): 0x%h | (Bin): %b", value, value);
	endtask
	

// Verification logic
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

// Verification and Statistics Counting
always @(posedge clk, negedge clk) begin
	
	stats1.clocks++;
	
	if (!tb_match) begin
		if (stats1.errors == 0) begin
			stats1.errortime = $time;
			first_mismatch_time = $time;
			first_mismatch_a = a;
			first_mismatch_q_ref = q_ref;
			first_mismatch_q_dut = q_dut;
			$display("!!! FIRST MISMATCH DETECTED !!!");
			// Display details at the first mismatch
		display_signal("Output Q", q_dut, a);
		display_signal("Reference Q", q_ref, a);
		display_signal("Input A", a, a);
		end
		stats1.errors++;
	end
	
// The original golden testbench logic for q_ref != (q_ref ^ q_dut ^ q_ref) is preserved
	if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
	begin 
		if (stats1.errors_q == 0) stats1.errortime_q = $time;
		sstats1.errors_q = stats1.errors_q+1'b1; 
	end
	end


// add timeout after 100K cycles
initial begin
  #1000000
  $display("\n==============================================\n");
  $display("TIMEOUT REACHED. Ending simulation.");
  $display("==============================================\n");
  $finish();
end

// Final Results Display (Improved Requirement)
initial begin
	@(negedge clk);
	#100; // Wait a little longer to allow final calculations if needed
	
	if (stats1.errors == 0) begin
		$display("\n==============================================\n");
		$display("SIMULATION PASSED");
		$display("==============================================\n");
	end else begin
		$display("\n==============================================\n");
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		$display("==============================================\n");
	end
	
	$display("\n==============================================\n");
	$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
	$display("Simulation finished at %0d ps", $time);
	$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end

endmodule