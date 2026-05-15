`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Module stimulus_gen from golden testbench
module stimulus_gen (
	input clk,
	output logic [3:0] in,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		in <= 0;
		@(negedge clk) wavedrom_start("All combinations");
			@(posedge clk);
			repeat(15) @(posedge clk) in <= in + 1;
		@(negedge clk) wavedrom_stop();	
		repeat(200) @(posedge clk, negedge clk)
		in <= $random;
	$finish;
	end

endmodule

// Reference Module (Assuming RefModule exists and matches the structure)
// Since its implementation is not provided, we must assume it's available for compilation.
module RefModule ( 
    input logic [3:0] in,
    output logic out_and,
    output logic out_or,
    output logic out_xor
);
	// Placeholder implementation matching specification for functional completeness
	assign out_and = in[0] & in[1] & in[2] & in[3];
	assign out_or = in[0] | in[1] | in[2] | in[3];
	assign out_xor = in[0] ^ in[1] ^ in[2] ^ in[3];
endmodule

// DUT Module (TopModule)
module TopModule (
    input  logic [3:0] in,
    output logic out_and,
    output logic out_or,
    output logic out_xor
);
	// Combinational implementation
	assign out_and = in[0] & in[1] & in[2] & in[3];
	assign out_or = in[0] | in[1] | in[2] | in[3];
	assign out_xor = in[0] ^ in[1] ^ in[2] ^ in[3];
endmodule


module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_and;
		int errortime_out_and;
		int errors_out_or;
		int errortime_out_or;
		int errors_out_xor;
		int errortime_out_xor;
		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [3:0] in;
	logic out_and_ref;
	logic out_and_dut;
	logic out_or_ref;
	logic out_or_dut;
	logic out_xor_ref;
	logic out_xor_dut;

	// Variables to store details of the FIRST mismatch
	logic [3:0] first_mismatch_in_val = 4'h0;
	logic out_and_val_ref_mismatch = 1'b0;
	logic out_and_val_dut_mismatch = 1'b0;
	logic out_or_val_ref_mismatch = 1'b0;
	logic out_or_val_dut_mismatch = 1'b0;
	logic out_xor_val_ref_mismatch = 1'b0;
	logic out_xor_val_dut_mismatch = 1'b0;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen::stim1, tb_mismatch ,in,out_and_ref,out_and_dut,out_or_ref,out_or_dut,out_xor_ref,out_xor_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.in );
	RefModule good1 (
		.in, 
		.out_and(out_and_ref),
		.out_or(out_or_ref),
		.out_xor(out_xor_ref) );
	
	TopModule top_module1 (
		.in,
		.out_and(out_and_dut),
		.out_or(out_or_dut),
		.out_xor(out_xor_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end	task
	
	
	initial begin
		$display("--- Starting Simulation ---");
	end

	
	final begin
		// --- Custom Final Display Logic --- 
		
		if (stats1.errors == 0) begin
			$display("=======================================");
			$display("SIMULATION PASSED");
			$display("=======================================");
			$display("Total tested cycles: %0d
", stats1.clocks);
			$finish;
		end
		
		if (stats1.errors > 0) begin
			$display("=======================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("---------------------------------------");
			$display("--- First Mismatch Details at Time %0d ps ---", stats1.errortime);
			$display("Input Signals (in): %h (%b)", first_mismatch_in_val, first_mismatch_in_val);
			$display("Reference Outputs: AND=%b, OR=%b, XOR=%b", out_and_ref, out_or_ref, out_xor_ref);
			$display("DUT Outputs:     AND=%b, OR=%b, XOR=%b", out_and_dut, out_or_dut, out_xor_dut);
			$display("---------------------------------------");
		end
		
		$display("Simulation finished at %0d ps", $time);
		end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_and_ref, out_or_ref, out_xor_ref } === ( { out_and_ref, out_or_ref, out_xor_ref } ^ { out_and_dut, out_or_dut, out_xor_dut } ^ { out_and_ref, out_or_ref, out_xor_ref } ) );
	
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			// Capture signals at the first mismatch time
			if (stats1.errors == 1) begin
				first_mismatch_in_val <= in;
				// We capture the values at the cycle where the mismatch occurred
				out_and_val_ref_mismatch <= out_and_ref;
				out_and_val_dut_mismatch <= out_and_dut;
				out_or_val_ref_mismatch <= out_or_ref;
				out_or_val_dut_mismatch <= out_or_dut;
				out_xor_val_ref_mismatch <= out_xor_ref;
				out_xor_val_dut_mismatch <= out_xor_dut;
			end
		end

		// Original error counting logic maintained, but enhanced for tracking
		if (out_and_ref !== ( out_and_ref ^ out_and_dut ^ out_and_ref ))
		begin 
			if (stats1.errors_out_and == 0) stats1.errortime_out_and = $time;
			sstats1.errors_out_and = stats1.errors_out_and+1'b1;
		end
		
		if (out_or_ref !== ( out_or_ref ^ out_or_dut ^ out_or_ref ))
		begin 
			if (stats1.errors_out_or == 0) stats1.errortime_out_or = $time;
			sstats1.errors_out_or = stats1.errors_out_or+1'b1;
		end
		
		if (out_xor_ref !== ( out_xor_ref ^ out_xor_dut ^ out_xor_ref ))
		begin 
			if (stats1.errors_out_xor == 0) stats1.errortime_out_xor = $time;
			sstats1.errors_out_xor = stats1.errors_out_xor+1'b1;
		end
		end

   // Add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED. Forcing simulation end.");
     $finish();
   end

endmodule