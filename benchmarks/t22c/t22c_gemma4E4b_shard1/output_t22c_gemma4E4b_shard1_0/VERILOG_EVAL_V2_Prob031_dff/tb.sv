`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// NOTE: stimulus_gen is kept as is, as per requirement 1.
module stimulus_gen (
	input clk,
	output reg d,
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
	
always @(posedge clk, negedge clk)
		d <= $urandom;
	
	initial begin
		@(posedge clk);
		wavedrom_start("Positive-edge triggered DFF");
		repeat(10) @(posedge clk);
		wavedrom_stop();
		
		repeat(100) @(posedge clk, negedge clk);
		$finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Capture registers for first mismatch display
	logic capture_d_err; // Input D at first error
	logic capture_q_dut_err; // DUT Output Q at first error
	logic capture_q_ref_err; // Ref Output Q at first error
	
	// For output Q mismatch
	logic capture_d_err_q;
	logic capture_q_dut_err_q;
	logic capture_q_ref_err_q;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	logic d;
	logic q_ref;
	logic q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,d,q_ref,q_dut );
	end

	
	wire tb_match;		// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		.d, 
		.wavedrom_title, 
		.wavedrom_enable 
	);
		
	// Reference Module (Assuming RefModule exists and implements DFF correctly)
	RefModule good1 (
		.clk,
		d,
		.q(q_ref) );
		
	// DUT Module
	TopModule top_module1 (
		.clk,
		d,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task
	
	
	// --- Verification Logic ---
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

	// Clocked process for statistics and error capture
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;

		// 1. Check for general mismatch (tb_match)
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time; // Capture first error time
			stats1.errors++;
			
			// Capture signals for general mismatch display
			capture_d_err = d;
			capture_q_dut_err = q_dut;
			capture_q_ref_err = q_ref;
			end

		// 2. Check for specific output Q mismatch
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time; // Capture first Q error time
			stats1.errors_q = stats1.errors_q+1'b1;
			
			// Capture signals for output mismatch display
			capture_d_err_q = d;
			capture_q_dut_err_q = q_dut;
			capture_q_ref_err_q = q_ref;
		end
		end

	// Finalization block (Replaces original final block)
	final begin
		if (stats1.errors_q == 0) begin
			$display("Hint: Output 'q' has no mismatches.");
		end else begin
			$display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
		end

	// Display detailed error information if errors occurred
	if (stats1.errors > 0 || stats1.errors_q > 0) begin
		$display("\n========================================================");
		$display("!!! ERROR DETECTED !!!");
		$display("Total mismatched samples (General) is %1d out of %1d samples.", stats1.errors, stats1.clocks);
		$display("Total mismatched samples (Output Q) is %1d out of %1d samples.", stats1.errors_q, stats1.clocks);
		$display("\n--- FIRST GENERAL MISMATCH DETAILS (Time: %0d) ---", stats1.errortime);
		$display("Time: %0d ps", stats1.errortime);
		$display("Inputs: D=%b (Hex: 0x%h)", capture_d_err, capture_d_err);
		$display("Outputs: Q_DUT=%b (Hex: 0x%h), Q_REF=%b (Hex: 0x%h)", capture_q_dut_err, capture_q_dut_err, capture_q_ref_err, capture_q_ref_err);
		$display("--------------------------------------------------------");
		
		$display("\n--- FIRST OUTPUT Q MISMATCH DETAILS (Time: %0d) ---", stats1.errortime_q);
		$display("Time: %0d ps", stats1.errortime_q);
		$display("Inputs: D=%b (Hex: 0x%h)", capture_d_err_q, capture_d_err_q);
		$display("Outputs: Q_DUT=%b (Hex: 0x%h), Q_REF=%b (Hex: 0x%h)", capture_q_dut_err_q, capture_q_dut_err_q, capture_q_ref_err_q, capture_q_ref_err_q);
		$display("--------------------------------------------------------");
	end

	// Final success/failure report
	if (stats1.errors == 0 && stats1.errors_q == 0) begin
		$display("\n**********************************");
		$display("SIMULATION PASSED");
		$display("**********************************");
	end else begin
		$display("\n**********************************");
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		$display("**********************************");
	end

	$display("Simulation finished at %0d ps", $time);
	$finish;
	endmodule
