`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [2:0] in,
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
		in <= 7;
		@(negedge clk);
		wavedrom_start();
		repeat(9) @(posedge clk) in <= in + 1'b1;
		@(negedge clk);
		wavedrom_stop();
		repeat(200) @(posedge clk, negedge clk)
		in <= $random;
		$finish;
	end
	
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
		logic [2:0] in_at_error;
		logic [1:0] out_ref_at_error;
		logic [1:0] out_dut_at_error;
	} stats;
	
	stats stats1;
	
	

	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [2:0] in;
	logic [1:0] out_ref;
	logic [1:0] out_dut;

	// Variables to store first mismatch details
	logic error_occurred = 0;
	integer first_error_time = 0;
	logic [2:0] first_in_val;
	logic [1:0] first_out_ref_val;
	logic [1:0] first_out_dut_val;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		in,
		.wavedrom_title, 
		.wavedrom_enable 
	);
	RefModule good1 (
		.in, 
		out(out_ref) );
	
	TopModule top_module1 (
		in,
		out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end	task
	
	
	final begin
		if (stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
			$display("Simulation finished at %0d ps", $time);
			$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
			end
		else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			
			$display("
--- FIRST MISMATCH DETAILS ---");
			$display("Time: %0d ps", stats1.errortime_out);
			
			// Display Input (in): 3 bits
			$display("Input (in): HEX=%h, BIN=%b", first_in_val, first_in_val);
			
			// Display Reference Output (out_ref): 2 bits
			$display("Reference Output (out_ref): HEX=%h, BIN=%b", first_out_ref_val, first_out_ref_val);
			
			// Display DUT Output (out_dut): 2 bits
			$display("DUT Output (out_dut): HEX=%h, BIN=%b", first_out_dut_val, first_out_dut_val);
			end
		end
		
		$display("Simulation finished at %0d ps", $time);
		$finish;
	end

	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
	// the sensitivity list of the @(strobe) process, which isn't implemented.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) begin
				stats1.errortime_out = $time;
			error_occurred = 1;
			first_error_time = $time;
			first_in_val = in; // Capture input
			out_ref_at_error = out_ref; // Capture reference output
			out_dut_at_error = out_dut; // Capture DUT output
			end
			
			sstats1.errors_out = stats1.errors_out+1'b1; 
		end
		end

		// Capture signals for detailed reporting only if this is the first error
		if (!tb_match && stats1.errors == 1 && !error_occurred) begin
			// Signals are captured above when stats1.errors_out == 0, maintaining fidelity.
			end
		end

		// add timeout after 100K cycles
		initial begin
			#1000000
			$display("TIMEOUT");
			$finish();
		end
	endmodule
