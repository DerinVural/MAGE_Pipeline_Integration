`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		output reg [7:0] d, output reg reset,
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
		s
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			s
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask



initial begin
	reset <= 1;
	d <= $random;
	wavedrom_start("Synchronous active-high reset");
	reset_test();
	repeat(10) @(negedge clk)
	d <= $random;
	wavedrom_stop();
	
	repeat(400) @(posedge clk, negedge clk) begin
		reset <= !($random & 15);
		d <= $random;
	end
	
	#1 $finish;
end

endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
	};
	
	stats stats1;
	

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;


initial forever
	#5 clk = ~clk;


logic [7:0] d;
logic reset;
logic [7:0] q_ref;
logic [7:0] q_dut;


logic [7:0] d_error_time_capture;
logic [7:0] q_ref_error_time_capture;
logic [7:0] q_dut_error_time_capture;


initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,clk,d,reset,q_ref,q_dut );
end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.d,
		.reset,
		.tb_match
);
RefModule good1 (
		.clk,
		d,
		.reset,
		.q(q_ref) );

TopModule top_module1 (
		.clk,
		d,
		.reset,
		.q(q_dut) );
	

bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
	endtask	

	final begin
		if (stats1.errors_q) begin
			$display("\n=========================================");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
			$display("\n--- First Output Mismatch Details (Time: %0d ps) ---", stats1.errortime_q);
			
			// Display D (8 bits)
			$display("Input D: Hex=%h, Binary=%b", d_error_time_capture, d_error_time_capture);
			
			// Display Q_ref (8 bits)
			$display("Expected Q (Ref): Hex=%h, Binary=%b", q_ref_error_time_capture, q_ref_error_time_capture);
			
			// Display Q_dut (8 bits)
			$display("Actual Q (DUT): Hex=%h, Binary=%b", q_dut_error_time_capture, q_dut_error_time_capture);
			$display("=========================================");
		end
		else begin
			$display("\n=========================================");
			$display("SIMULATION PASSED");
			$display("=========================================");
		end
		
		$display("\n--- Summary ---");
		$display("Total mismatched samples (Overall): %1d out of %1d samples", stats1.errors, stats1.clocks);
		$display("Total mismatched samples (Output Q): %1d out of %1d samples", stats1.errors_q, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("-------------------");
	end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin
	
	stats1.clocks++;
		if (!tb_match) begin
		if (stats1.errors == 0) stats1.errortime = $time;
		stats1.errors++;
	end
	
	// Check for output mismatch (q_ref vs q_dut)
	if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
	begin 
		if (stats1.errors_q == 0) 
		stats1.errortime_q = $time;
		// Capture signals at the time of first q mismatch
		d_error_time_capture = d;
		q_ref_error_time_capture = q_ref;
		q_dut_error_time_capture = q_dut;
		
		stats1.errors_q = stats1.errors_q+1'b1;
	end

endmodule


module RefModule ( // Required to match original instantiation
		input clk,
		input [7:0] d,
		input reset,
		output [7:0] q
);
		// Placeholder for reference model logic
		always @(posedge clk)
			q <= d;
endmodule
