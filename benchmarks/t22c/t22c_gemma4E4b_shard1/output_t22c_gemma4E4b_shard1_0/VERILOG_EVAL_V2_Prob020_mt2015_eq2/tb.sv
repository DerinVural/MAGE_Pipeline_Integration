`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13
/*
	Midterm 2015 Question 1k. 2-bit equality comparator.
*/


module stimulus_gen (
	input clk,
	output logic [1:0] A,
	output logic [1:0] B
);

	always @(posedge clk, negedge clk)
		{A, B} <= $random % 16;
	
	initial begin
		repeat(1000) @(negedge clk);
		#1 $finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
	};
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [1:0] A;
	logic [1:0] B;
	logic z_ref;
	logic z_dut;

	logic [1:0] first_mismatch_A_bin, first_mismatch_A_hex;
	logic [1:0] first_mismatch_B_bin, first_mismatch_B_hex;
	logic first_mismatch_Zdut_bin, first_mismatch_Zdut_hex;
	logic first_mismatch_Zref_bin, first_mismatch_Zref_hex;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,A,B,z_ref,z_dut );
	end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.* ,
		.A,
		.B );
RefModule good1 (
		.A,
		.B,
		.z(z_ref) );

TopModule top_module1 (
		.A,
		.B,
		.z(z_dut) );
	

bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	end
task endtask
	

initial begin
		stats1 = '{default: 0};
		
		// Wait a little before starting meaningful checks
		repeat(10) @(posedge clk);
	end
	

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
	
// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
	
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				s1.errortime = $time;
				// Capture signals at the time of the first mismatch
				first_mismatch_A_bin = A;
				first_mismatch_A_hex = A;
				first_mismatch_B_bin = B;
				first_mismatch_B_hex = B;
				first_mismatch_Zdut_bin = z_dut;
				first_mismatch_Zdut_hex = z_dut;
				first_mismatch_Zref_bin = z_ref;
				first_mismatch_Zref_hex = z_ref;
				end
			sstats1.errors++;
		end
		
		// Original logic check for z_ref mismatch (kept for continuity, though likely redundant given tb_match)
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin 
			if (stats1.errors_z == 0) stats1.errortime_z = $time;
			sstats1.errors_z = stats1.errors_z + 1'b1; 
		end
	end
	
// add timeout after 100K cycles
initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
end	
	
// Final Check and Display
final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end
	else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- First Mismatch Details (Time: %0d ps) ---", stats1.errortime);
			// Display Inputs: A and B (2-bit width <= 64, so show both HEX and BIN)
			$display("Inputs: A = %h (%b), B = %h (%b)", first_mismatch_A_hex, first_mismatch_A_bin, first_mismatch_B_hex, first_mismatch_B_bin);
			// Display Outputs: DUT z and REF z (1-bit width <= 64, so show both HEX and BIN)
			$display("Outputs: DUT z = %h (%b), REF z = %h (%b)", first_mismatch_Zdut_hex, first_mismatch_Zdut_bin, first_mismatch_Zref_hex, first_mismatch_Zref_bin);
			$display("--------------------------------------------");
	end
endmodule