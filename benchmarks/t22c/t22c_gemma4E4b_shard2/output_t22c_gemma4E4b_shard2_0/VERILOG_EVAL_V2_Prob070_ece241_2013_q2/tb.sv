`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator Module (Copied for completeness as it is part of the original structure) ---
module stimulus_gen (
	input clk,
	output logic a, b, c, d,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	bit fail = 0;
	bit fail1 = 0;
	always @(posedge clk, negedge clk)
		if (!tb_match)
			fail = 1;

	initial begin
		@(posedge clk) {a,b,c,d} <= 0;
		@(posedge clk) {a,b,c,d} <= 1;
		@(posedge clk) {a,b,c,d} <= 2;
		@(posedge clk) {a,b,c,d} <= 4;
		@(posedge clk) {a,b,c,d} <= 5;
		@(posedge clk) {a,b,c,d} <= 6;
		@(posedge clk) {a,b,c,d} <= 7;
		@(posedge clk) {a,b,c,d} <= 9;
		@(posedge clk) {a,b,c,d} <= 10;
		@(posedge clk) {a,b,c,d} <= 13;
		@(posedge clk) {a,b,c,d} <= 14;
		@(posedge clk) {a,b,c,d} <= 15;
		@(posedge clk) fail1 = fail;
		
		
		
		//@(negedge clk) wavedrom_start();
			for (int i=0;i<16;i++)
				@(posedge clk)
					{a,b,c,d} <= i;
			//@(negedge clk) wavedrom_stop();
			
		repeat(50) @(posedge clk, negedge clk)
			{a,b,c,d} <= $random;
		
		if (fail && ~fail1)
			$display("Hint: Your circuit passes on the 12 required input combinations, but doesn't match the don't-care cases. Are you using minimal SOP and POS?");

		$finish;
	end
	endmodule

// --- Reference Module (Assuming this is the golden reference logic) ---
module RefModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out_sop,
    output logic out_pos
);
	// Based on the specification: Output 1 for {2, 7, 15}. (a,b,c,d) map to 0..15.
	// Assuming inputs map to value V = d*8 + c*4 + b*2 + a*1 based on typical indexing for 7=(0,1,1,1) -> 14 if a=LSB.
	// Since the exact mapping is ambiguous, we implement the core logic for {2, 7, 15} yielding 1.
	// We assume standard binary ordering for the value V: V = d*8 + c*4 + b*2 + a*1
	
	localparam V_2 = 2'b0010;
	localparam V_7 = 7'b0000111;
	localparam V_15 = 15'b00001111;

	// Calculate value V
	logic [3:0] V;
	assign V = {d, c, b, a};

	// out_sop (Minimum Sum-of-Products form)
	// True when V is 2, 7, or 15
	out_sop = (V == 4'b0010) || (V == 4'b0111) || (V == 4'b1111);

	// out_pos (Minimum Product-of-Sums form)
	// True when V is NOT 0, 1, 4, 5, 6, 9, 10, 13, or 14 (i.e., V is 2, 7, or 15)
	out_pos = (V == 4'b0010) || (V == 4'b0111) || (V == 4'b1111);

endmodule

module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_sop;
		int errortime_out_sop;
		int errors_out_pos;
		int errortime_out_pos;
		int clocks;
		// Storage for first mismatch state
		logic [3:0] first_a, first_b, first_c, first_d;
		logic first_out_sop_ref, first_out_sop_dut;
		logic first_out_pos_ref, first_out_pos_dut;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic a;
	logic b;
	logic c;
	logic d;
	logic out_sop_ref;
	logic out_sop_dut;
	logic out_pos_ref;
	logic out_pos_dut;

	// Helper function to display signals in HEX and BIN
	task display_signal(string name, logic signal_val, int width = 1);
	begin
		$display("\t\t%s: %h (Binary: %b)", name, signal_val, signal_val);
	end
	endtask

	// Helper function to display multi-bit signals
	task display_multi_signal(string name, logic [3:0] signal_val);
	begin
		$display("\t\t%s: %h (Binary: %b)", name, signal_val, signal_val);
	end
	endtask

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,out_sop_ref,out_sop_dut,out_pos_ref,out_pos_dut );
	end

	wire tb_match;
	// Maintain original contradictory logic:
	assign tb_match = ( { out_sop_ref, out_pos_ref } === ( { out_sop_ref, out_pos_ref } ^ { out_sop_dut, out_pos_dut } ^ { out_sop_ref, out_pos_ref } ) );
	
	stimulus_gen stim1 (
		.clk,
		.* , 
		.a,
		.b,
		.c,
		.d);
		
	RefModule good1 (
		.a,
		.b,
		.c,
		.d,
		.out_sop(out_sop_ref),
		.out_pos(out_pos_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.c,
		.d,
		.out_sop(out_sop_dut),
		.out_pos(out_pos_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
	begin
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask
	
	// Reset stats initialization
	initial begin
		stats1 = '{errors: 0, errortime: 0, errors_out_sop: 0, errortime_out_sop: 0, errors_out_pos: 0, errortime_out_pos: 0, clocks: 0};
	end
	
	// Verification Loop
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			// Overall Mismatch Tracking
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Specific SOP Mismatch Tracking
		if (out_sop_ref !== ( out_sop_ref ^ out_sop_dut ^ out_sop_ref ))
		begin 
			if (stats1.errors_out_sop == 0) stats1.errortime_out_sop = $time;
			sstats1.errors_out_sop = stats1.errors_out_sop+1'b1;
		end
		
		// Specific POS Mismatch Tracking
		if (out_pos_ref !== ( out_pos_ref ^ out_pos_dut ^ out_pos_ref ))
		begin 
			if (stats1.errors_out_pos == 0) stats1.errortime_out_pos = $time;
			sstats1.errors_out_pos = stats1.errors_out_pos+1'b1;
		end
	end
	
	// Capture state on FIRST mismatch for detailed display
	always @(posedge clk, negedge clk) begin
		if (!tb_match && stats1.errors == 1) begin
			stats1.first_a <= a; stats1.first_b <= b; stats1.first_c <= c; stats1.first_d <= d;
			stats1.first_out_sop_ref <= out_sop_ref; stats1.first_out_sop_dut <= out_sop_dut;
			stats1.first_out_pos_ref <= out_pos_ref; stats1.first_out_pos_dut <= out_pos_dut;
		end
	end

	// Add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final Reporting Block (Improved)
	initial begin
		@(negedge clk);
		// Wait for simulation to settle after last stimulus if necessary, although $finish handles this.
		
		$display("============================================================");
		
		if (stats1.errors_out_sop > 0)
		begin
			$display("\n--- OUT_SOP MISMATCH DETAILS ---");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_sop, stats1.errortime_out_sop);
			$display("\nState at first SOP mismatch (Time: %0d ps):", stats1.errortime_out_sop);
			$display("  Inputs (a, b, c, d): ");
			display_multi_signal("  a", stats1.first_a);
			display_multi_signal("  b", stats1.first_b);
			display_multi_signal("  c", stats1.first_c);
			display_multi_signal("  d", stats1.first_d);
			$display("  Reference Output (out_sop_ref): %h (Binary: %b)", stats1.first_out_sop_ref, stats1.first_out_sop_ref);
			$display("  DUT Output (out_sop_dut):     %h (Binary: %b)", stats1.first_out_sop_dut, stats1.first_out_sop_dut);
		end
		if (stats1.errors_out_sop == 0)
			$display("\nOutput 'out_sop' PASSED (0 mismatches).");
		
		if (stats1.errors_out_pos > 0)
		begin
			$display("\n--- OUT_POS MISMATCH DETAILS ---");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_pos, stats1.errortime_out_pos);
			$display("\nState at first POS mismatch (Time: %0d ps):", stats1.errortime_out_pos);
			$display("  Inputs (a, b, c, d): ");
			display_multi_signal("  a", stats1.first_a);
			display_multi_signal("  b", stats1.first_b);
			display_multi_signal("  c", stats1.first_c);
			display_multi_signal("  d", stats1.first_d);
			$display("  Reference Output (out_pos_ref): %h (Binary: %b)", stats1.first_out_pos_ref, stats1.first_out_pos_ref);
			$display("  DUT Output (out_pos_dut):     %h (Binary: %b)", stats1.first_out_pos_dut, stats1.first_out_pos_dut);
		end
		if (stats1.errors_out_pos == 0)
			$display("\nOutput 'out_pos' PASSED (0 mismatches).");
		
		// Final Summary based on overall errors
		if (stats1.errors > 0)
			$display("\n============================================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- First Overall Mismatch State (Time: %0d ps) ---", stats1.errortime);
			$display("  Inputs (a, b, c, d): ");
			display_multi_signal("  a", stats1.first_a);
			display_multi_signal("  b", stats1.first_b);
			display_multi_signal("  c", stats1.first_c);
			display_multi_signal("  d", stats1.first_d);
			$display("  Reference Output (out_sop_ref): %h (Binary: %b)", stats1.first_out_sop_ref, stats1.first_out_sop_ref);
			$display("  DUT Output (out_sop_dut):     %h (Binary: %b)", stats1.first_out_sop_dut, stats1.first_out_sop_dut);
			$display("  Reference Output (out_pos_ref): %h (Binary: %b)", stats1.first_out_pos_ref, stats1.first_out_pos_ref);
			$display("  DUT Output (out_pos_dut):     %h (Binary: %b)", stats1.first_out_pos_dut, stats1.first_out_pos_dut);
		
		
		
		if (stats1.errors == 0)
			$display("============================================================");
			$display("SIMULATION PASSED");
		end
	end

endmodule
