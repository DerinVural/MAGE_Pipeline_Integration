`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assuming RefModule is defined elsewhere and available for instantiation
// Assuming TopModule is defined elsewhere and available for instantiation

module stimulus_gen (
	input clk,
	output logic [254:0] in,
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
		in <= 255'h0;
		wavedrom_start("");
		@(posedge clk, negedge clk) in <= 255'h0;
		@(posedge clk, negedge clk) in <= 255'h0;
		@(posedge clk, negedge clk) in <= 255'h1;
		@(posedge clk, negedge clk) in <= 255'h1;
		@(posedge clk, negedge clk) in <= 255'h3;
		@(posedge clk, negedge clk) in <= 255'h3;
		@(posedge clk, negedge clk) in <= 255'h7;
		@(posedge clk, negedge clk) in <= 255'haaaa;
		@(posedge clk, negedge clk) in <= 255'hf00000;
		@(posedge clk, negedge clk) in <= 255'h0;
		wavedrom_stop();
		repeat (200) @(posedge clk, negedge clk) begin
		in <= {$random, $random, $random, $random, $random, $random, $random, $random};
		end
		@(posedge clk);
		in <= '0;
		@(posedge clk)
		in <= '1;
		@(posedge clk)
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
		#5 clk = ~clk;

	logic [254:0] in;
	logic [7:0] out_ref;
	logic [7:0] out_dut;

	// Variables to capture first mismatch state for combinational logic display
	logic first_mismatch_captured = 0;
	logic [254:0] input_at_mismatch;
	logic [7:0] output_dut_at_mismatch;
	logic [7:0] output_ref_at_mismatch;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		in );
	RefModule good1 (
		.in,
		.out(out_ref) );
	
	TopModule top_module1 (
		.in,
		out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
		endtask
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Monitor logic, adapted for combinational failure capture
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// General mismatch error counting (Original Logic)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		
		// Output mismatch error counting (Original Logic)
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1;
		end
		
		// Combinational Mismatch Capture (New Logic for first mismatch display)
		if (!tb_match && !first_mismatch_captured) begin
			// Capture state at the time of first mismatch
			input_at_mismatch = in;
			output_dut_at_mismatch = out_dut;
			output_ref_at_mismatch = out_ref;
			first_mismatch_captured = 1;
		end
	end

	
	initial begin
		// Wait until the first mismatch occurs to display the state (Combinational Logic)
		@(posedge clk);
		wait(first_mismatch_captured);
		
		if (stats1.errors > 0) begin
			$display("\n========================================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- First Mismatch State ---");
			$display("Time of First Mismatch: %0d ps", stats1.errortime);
			$display("Input (in) [255:0]:  %h (Binary: %b)", input_at_mismatch, input_at_mismatch);
			$display("Expected Output (out_ref) [7:0]: %h (Binary: %b)", output_ref_at_mismatch, output_ref_at_mismatch);
			$display("Actual Output (out_dut) [7:0]:  %h (Binary: %b)", output_dut_at_mismatch, output_dut_at_mismatch);
			$display("========================================================\n");
		end
		else begin
			$display("\n========================================================");
			SIMULATION PASSED
			========================================================\n");
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule