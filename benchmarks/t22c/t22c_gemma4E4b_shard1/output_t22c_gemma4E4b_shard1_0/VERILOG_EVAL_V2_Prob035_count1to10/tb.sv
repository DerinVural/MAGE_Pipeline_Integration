`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator (Kept as per Golden Testbench) ---
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
			s$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
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
		wavedrom_start("Synchronous reset and counting.");
		reset_test();
		repeat(12) @(posedge clk);
		wavedrom_stop();
		@(posedge clk);
		
		repeat(400) @(posedge clk, negedge clk) begin
		reset <= !($random & 31);
		end
		#1 $finish;
	end
	
	endmodule

// --- DUT Placeholder (Since implementation is not provided, we use a simple placeholder) ---
module TopModule (
    input clk,
    input reset,
    output logic [3:0] q
);
    // Placeholder implementation: Counts 1 through 10
    reg [3:0] counter = 4'd1;
    always @(posedge clk)
    begin
        if (reset)
            counter <= 4'd1;
        else if (counter == 4'd10)
            counter <= 4'd1;
        else
            counter <= counter + 1;
    end
    assign q = counter;
endmodule

// --- Reference Module Placeholder (Must exist for TB to compile) ---
module RefModule (
    input clk,
    input reset,
    output logic [3:0] q
);
    // Reference implementation (same logic)
    reg [3:0] counter = 4'd1;
    always @(posedge clk)
    begin
        if (reset)
            counter <= 4'd1;
        else if (counter == 4'd10)
            counter <= 4'd1;
        else
            counter <= counter + 1;
    end
    assign q = counter;
endmodule

// --- Testbench ---
module tb();

	typedef struct packed {
		int errors;          // Total mismatches
		int errortime;       // Time of first mismatch
		int errors_q;        // Mismatches specific to q output
		int errortime_q;     // Time of first q mismatch
		int clocks;          // Total cycles run
		logic [3:0] mismatch_q_dut; // Value of q_dut at first q mismatch
		logic [3:0] mismatch_q_ref; // Value of q_ref at first q mismatch
		logic [3:0] mismatch_q_expected; // Expected value (q_ref) at first q mismatch
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic reset;
	logic [3:0] q_ref;
	logic [3:0] q_dut;

	// Signals to capture state at first error
	logic [3:0] q_mismatch_dut_capture = 4'bx;
	logic [3:0] q_mismatch_ref_capture = 4'bx;
	logic [3:0] q_mismatch_expected_capture = 4'bx;
	
	initial begin 
		$dumpfile("wave.vcd");
		// Include all relevant signals from the golden TB
		$dumpvars(1, stimulus_gen::stim1, tb, clk, reset, q_ref, q_dut, q_mismatch_dut_capture, q_mismatch_ref_capture, q_mismatch_expected_capture);
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiate stimulus_gen (Must match golden TB instantiation structure)
	stimulus_gen stim1 (
		.clk, 
		.reset, 
		.wavedrom_title(wavedrom_title), 
		.wavedrom_enable(wavedrom_enable),
		.tb_match(tb_match)
	);
	
	// Instantiate RefModule	
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
		end	ask
	
	// Custom display task for multi-bit signals	
	task display_signal(input string name, input logic [3:0] signal);
		$display("  [%s] Current Value: %0d (HEX: %h, BIN: %b)", name, signal, signal, signal);
	endtask

	final begin
		$display("======================================================");
		if (stats1.errors == 0) begin
			s$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
			$display("INPUTS: clk=%b, reset=%b", clk, reset);
			$display("OUTPUTS: q_dut = %0d (HEX: %h, BIN: %b)", q_dut, q_dut, q_dut);
			$display("EXPECTED: q_ref = %0d (HEX: %h, BIN: %b)", q_ref, q_ref, q_ref);
			end
		$display("Total mismatched samples is %0d out of %0d samples\n", stats1.errors, stats1.clocks);
		$display("======================================================");
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		
		// --- Error Counting Logic (Main Mismatch) ---
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			s$display("*** FIRST MAJOR MISMATCH DETECTED at time %0d ***", $time);
			// Capture state at first major mismatch
			q_mismatch_dut_capture <= q_dut;
			q_mismatch_ref_capture <= q_ref;
			q_mismatch_expected_capture <= q_ref; // Expected is always q_ref
			// Display details for the first mismatch
			$display("  [Input] clk=%b, reset=%b", clk, reset);
			$display("  [Output] q_dut = %0d (HEX: %h, BIN: %b)", q_dut, q_dut, q_dut);
			$display("  [Expected] q_ref = %0d (HEX: %h, BIN: %b)", q_ref, q_ref, q_ref);
			stats1.errors++;
			end
		
		// --- Specific q Output Mismatch Logic (Inherited from Golden TB) ---
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			// Capture state at first q mismatch
			q_mismatch_dut_capture <= q_dut;
			q_mismatch_ref_capture <= q_ref;
			q_mismatch_expected_capture <= q_ref; 
			s$display("*** FIRST Q SPECIFIC MISMATCH DETECTED at time %0d ***", $time);
			// Display details for the first q mismatch
			$display("  [Input] clk=%b, reset=%b", clk, reset);
			$display("  [Output] q_dut = %0d (HEX: %h, BIN: %b)", q_dut, q_dut, q_dut);
			$display("  [Expected] q_ref = %0d (HEX: %h, BIN: %b)", q_ref, q_ref, q_ref);
			s{stats1.errors_q = stats1.errors_q+1'b1; }
		end

	end		// End of always block

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule
