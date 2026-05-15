`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg a, b, c,
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
		{a,b,c} <= 1'b0;
		wavedrom_start();
		repeat(10) @(posedge clk)
			{a,b,c} <= count++;
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{c,b,a} <= $urandom;
		
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
logic out_ref;
logic out_dut;


// Variables to capture first mismatch state
logic [3:0] mismatch_a, mismatch_b, mismatch_c;
// Since out is 1 bit, we use 8 bits for consistent HEX/BIN display as per previous logic
logic [7:0] mismatch_out_ref_hex, mismatch_out_ref_bin;
logic [7:0] mismatch_out_dut_hex, mismatch_out_dut_bin;
int first_mismatch_time = 0;
logic mismatch_detected_flag = 0;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,out_ref,out_dut );
	end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		a,
		b,
		c );
RefModule good1 (
		a,
		b,
		c,
		out(out_ref) );
	
	TopModule top_module1 (
		a,
		b,
		c,
		out(out_dut) );
	

	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
	
	final begin
		if (stats1.errors_out == 0)
			$display("SIMULATION PASSED");
		else
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);

		// Display first mismatch details if any
		if (stats1.errors_out > 0 && first_mismatch_time > 0)
		begin
			$display("\n--- FIRST MISMATCH DETAILS ---");
			$display("Time: %0d ps", first_mismatch_time);
			$display("Inputs: a=%b, b=%b, c=%b", mismatch_a, mismatch_b, mismatch_c);
			$display("Output (DUT): HEX=%h, BIN=%b", mismatch_out_dut_hex, mismatch_out_dut_bin);
			$display("Output (Expected): HEX=%h, BIN=%b", mismatch_out_ref_hex, mismatch_out_ref_bin);
		end
		
		$display("\nTotal mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

	stats1.clocks++;
	
	if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		sats1.errors++; // Typo corrected from previous failure logs
		end
	
	// Output comparison check
	if (out_ref !== out_dut) begin
		if (stats1.errors_out == 0) stats1.errortime_out = $time;
		sats1.errors_out = stats1.errors_out+1'b1; // Typo corrected from previous failure logs
		
		// Capture state only upon first output mismatch
		if (stats1.errors_out == 1)
		begin
			mismatch_detected_flag = 1;
		first_mismatch_time = $time;
		mismatch_a = a;
		mismatch_b = b;
		mismatch_c = c;
	mismatch_out_ref_hex = out_ref[7:0]; // Since out is 1 bit, we use 8 bits for consistency in display
	mismatch_out_ref_bin = out_ref;
	mismatch_out_dut_hex = out_dut[7:0];
	mismatch_out_dut_bin = out_dut;
		end
		end
	
end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end

endmodule