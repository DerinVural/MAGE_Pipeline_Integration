`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output reg a, b,
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
		int count; count = 0;
		{a,b} <= 1'b0;
		wavedrom_start("XNOR gate");
		repeat(10) @(posedge clk)
			{a,b} <= count++;
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{b,a} <= $random;
		
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
		// Capture state for first mismatch
		logic a_mismatch_state;
		logic b_mismatch_state;
		logic out_dut_mismatch_state;
		logic out_ref_mismatch_state;
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
logic out_ref;
logic out_dut;

	
initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,out_ref,out_dut );
	end


wire tb_match;	// Verification
wire tb_mismatch = ~tb_match;
	

stimulus_gen stim1 (
		.clk,
		.* , 
		.a,
		.b );
RefModule good1 (
		.a,
		.b,
		.out(out_ref) );

TopModule top_module1 (
		a,
		b,
		out_dut );



bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	

final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
			$display("Hint: Output 'out' has no mismatches.");
			$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
			$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
			end
		else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			// Display state at first mismatch time
			$display("--- FIRST MISMATCH DETAILS (Time %0d ps) ---", stats1.errortime);
			$display("Inputs: a=%b, b=%b", stats1.a_mismatch_state, stats1.b_mismatch_state);
			$display("Outputs: DUT_out=%b, REF_out=%b", stats1.out_dut_mismatch_state, stats1.out_ref_mismatch_state);
			$display("---------------------------------------------");
			end
	end
	

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
	
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Capture state at first error
			s1.a_mismatch_state = a;
			s1.b_mismatch_state = b;
			s1.out_dut_mismatch_state = out_dut;
			s1.out_ref_mismatch_state = out_ref;
			end
			s1.errors++;
		end
		
		// This check seems to be an internal/specific verification logic from the original golden TB that must be kept.
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			s1.errors_out = stats1.errors_out+1'b1; 
		end
		end


// add timeout after 100K cycles
initial begin
  #1000000
  $display("TIMEOUT");
  $finish();
end

endmodule