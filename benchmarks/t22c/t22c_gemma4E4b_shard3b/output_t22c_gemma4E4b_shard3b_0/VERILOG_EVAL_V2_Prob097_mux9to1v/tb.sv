 `timescale 1 ps/1 ps
 `define OK 12
 `define INCORRECT 13
 
 // --- stimulus_gen Module (Copied from Golden TB to maintain environment) ---
 module stimulus_gen (
 	input clk,
 	output logic [15:0] a,b,c,d,e,f,g,h,i,
 	output logic [3:0] sel,
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
 			{a,b,c,d,e,f,g,h,i,sel} <= { 16'ha, 16'hb, 16'hc, 16'hd, 16'he, 16'hf, 16'h11, 16'h12, 16'h13, 4'h0 };
 			@(negedge clk) wavedrom_start();
 				@(posedge clk) sel <= 4'h1;
 				@(posedge clk) sel <= 4'h2;
 				@(posedge clk) sel <= 4'h3;
 				@(posedge clk) sel <= 4'h4;
 				@(posedge clk) sel <= 4'h7;
 				@(posedge clk) sel <= 4'h8;
 				@(posedge clk) sel <= 4'h9;
 				@(posedge clk) sel <= 4'ha;
 				@(posedge clk) sel <= 4'hb;
 			@(negedge clk) wavedrom_stop();
 				
 			repeat(200) @(negedge clk, posedge clk) begin
 				{a,b,c,d,e,f,g,h,i,sel} <= {$random, $random, $random, $random, $random};
 			end
 			$finish;
 	end
 	
 endmodule
 
 // --- Testbench Module ---
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
 
 	logic [15:0] a;
 	logic [15:0] b;
 	logic [15:0] c;
 	logic [15:0] d;
 	logic [15:0] e;
 	logic [15:0] f;
 	logic [15:0] g;
 	logic [15:0] h;
 	logic [15:0] i;
 	logic [3:0] sel;
 	logic [15:0] out_ref;
 	logic [15:0] out_dut;
 
 	// Variables to track first error time for final summary
 	int first_mismatch_time = -1;
 	int first_output_mismatch_time = -1;
 	
 	initial begin 
 		$dumpfile("wave.vcd");
 		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,e,f,g,h,i,sel,out_ref,out_dut );
 	end
 
 	
 	// Helper task to display signals in HEX and BIN format
 	task display_signals(time t);
 		$display("====================================================");
 		$display("*** MISMATCH DETECTED AT TIME %0t ps ***", t);
 		$display("--- Input Signals ---");
 		$display("A: HEX=%h, BIN=%b", a, a);
 		$display("B: HEX=%h, BIN=%b", b, b);
 		$display("C: HEX=%h, BIN=%b", c, c);
 		$display("D: HEX=%h, BIN=%b", d, d);
 		$display("E: HEX=%h, BIN=%b", e, e);
 		$display("F: HEX=%h, BIN=%b", f, f);
 		$display("G: HEX=%h, BIN=%b", g, g);
 		$display("H: HEX=%h, BIN=%b", h, h);
 		$display("I: HEX=%h, BIN=%b", i, i);
 		$display("SEL: HEX=%h, BIN=%b", sel, sel);
 		$display("--- Output Signals ---");
 		$display("Expected (Ref): HEX=%h, BIN=%b", out_ref, out_ref);
 		$display("DUT Output: HEX=%h, BIN=%b", out_dut, out_dut);
 		$display("====================================================");
 	endtask
 	
 	
 	wire tb_match;
 	wire tb_mismatch = ~tb_match;
 	
 	stimulus_gen stim1 (
 		.clk, 
 		.* , 
 		.a, 
 		.b, 
 		.c, 
 		.d, 
 		.e, 
 		.f, 
 		.g, 
 		.h, 
 		.i, 
 		.sel );
 	RefModule good1 (
 		.a, 
 		.b, 
 		.c, 
 		.d, 
 		.e, 
 		.f, 
 		.g, 
 		.h, 
 		.i, 
 		.sel, 
 		.out(out_ref) );
 	
 	TopModule top_module1 (
 		a, 
 		b, 
 		c, 
 		d, 
 		e, 
 		f, 
 		g, 
 		h, 
 		i, 
 		.sel, 
 		out(out_dut) );
 	
 	
 	bit strobe = 0;
 	task wait_for_end_of_timestep;
 		repeat(5) begin
 			strobe <= !strobe;  // Try to delay until the very end of the time step.
 			@(strobe);
 		end
 	endtask
 	
 	
 	final begin
 		if (stats1.errors_out == 0) begin
 		$display("SIMULATION PASSED");
 		end else begin
 		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
 		end
 	end
 	
 	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
 	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
 	
 	// Main verification logic block
 	always @(posedge clk, negedge clk) begin
 		stats1.clocks++;
 		
 		// Track overall errors
 		if (!tb_match) begin
 			if (stats1.errors == 0) stats1.errortime = $time;
 			sstats1.errors++;
 			// Capture first overall mismatch time
 		if (first_mismatch_time == -1) first_mismatch_time = $time;
 		end
 		
 		// Track output errors
 		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
 		begin 
 			if (stats1.errors_out == 0) stats1.errortime_out = $time;
 			sstats1.errors_out = stats1.errors_out+1'b1; 
 			// Capture first output mismatch time
 		if (first_output_mismatch_time == -1) first_output_mismatch_time = $time;
 		end
 	end
 
 	// Trigger display upon first error detection
 	always @(posedge clk, negedge clk) begin
 		if (first_mismatch_time == $time && tb_mismatch) begin
 			display_signals($time);
 			first_mismatch_time = -2; // Mark as displayed
 		end
 		if (first_output_mismatch_time == $time && (out_ref !== ( out_ref ^ out_dut ^ out_ref ))) begin
 			display_signals($time);
 			first_output_mismatch_time = -2; // Mark as displayed
 		end
 	end
 	
 	// add timeout after 100K cycles
 	initial begin
 		#1000000
 		$display("TIMEOUT");
 		$finish();
 	end
 	
 endmodule
 
 // Placeholder for RefModule definition (Required by golden TB structure)
 module RefModule (input [15:0] a, input [15:0] b, input [15:0] c, input [15:0] d, input [15:0] e, input [15:0] f, input [15:0] g, input [15:0] h, input [15:0] i, input [3:0] sel, output logic [15:0] out);
 	assign out = (sel == 4'h0) ? a : (sel == 4'h1) ? b : (sel == 4'h2) ? c : (sel == 4'h3) ? d : (sel == 4'h4) ? e : (sel == 4'h5) ? f : (sel == 4'h6) ? g : (sel == 4'h7) ? h : (sel == 4'h8) ? i : (sel == 4'h9) ? a : 16'hFFFF; // Mock implementation for compilation
 endmodule
 
 // TopModule definition (As per input spec, used by the TB)
 module TopModule (
 	input  logic [15:0] a,
 	input  logic [15:0] b,
 	input  logic [15:0] c,
 	input  logic [15:0] d,
 	input  logic [15:0] e,
 	input  logic [15:0] f,
 	input  logic [15:0] g,
 	input  logic [15:0] h,
 	input  logic [15:0] i,
 	input  logic [3:0] sel,
 	output logic [15:0] out
);
 	
 	// 16-bit wide 9-to-1 Multiplexer implementation using combinational logic
 	always @* begin
 		case (sel)
 			4'h0: out = a;
 			4'h1: out = b;
 			4'h2: out = c;
 			4'h3: out = d;
 			4'h4: out = e;
 			4'h5: out = f;
 			4'h6: out = g;
 			4'h7: out = h;
 			4'h8: out = i;
 			// Default case covers sel = 9 (1001) through sel = 15 (1111)
 			default: out = 16'hFFFF;
 		endcase
 	end
 	
 endmodule