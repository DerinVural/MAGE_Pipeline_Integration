`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Replicating stimulus_gen as provided in the golden testbench
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
		wavedrom_start("AND gate");
		repeat(10) @(posedge clk)
			{a,b} <= count++;
		wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{b,a} <= $random;
		
		#1 $finish;
	end
	endmodule


// Placeholder for RefModule as it was used in the golden testbench
module RefModule (
	input a,
	input b,
	output out_assign,
	output out_alwaysblock
);
	// Assuming simple AND gate implementation for reference
	assign out_assign = a & b;
	always @(*) begin
		out_alwaysblock = a & b;
	end
endmodule


// The DUT module implementation based on specification (AND gate)
module TopModule (
    input  logic a,
    input  logic b,
    output logic out_assign,
    output logic out_alwaysblock
);
    // AND gate using assign statement
    assign out_assign = a & b;

    // AND gate using combinational always block
    always @(*) begin
        out_alwaysblock = a & b;
    end
endmodule


module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_assign;
		int errortime_out_assign;
		int errors_out_alwaysblock;
		int errortime_out_alwaysblock;
		int clocks;
		// State capture for first mismatch reporting
		logic err_a_capture;
		logic err_b_capture;
		logic err_out_assign_ref_capture;
		logic err_out_alwaysblock_ref_capture;
		logic err_out_assign_dut_capture;
		logic err_out_alwaysblock_dut_capture;
	} stats;
	
	stats stats1;
	
	
	// Waveform monitoring signals from stimulus_gen
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic a;
	logic b;
	logic out_assign_ref;
	logic out_assign_dut;
	logic out_alwaysblock_ref;
	logic out_alwaysblock_dut;

	// Capture variables for reporting
	logic captured_a, captured_b, captured_out_assign_ref, captured_out_alwaysblock_ref, captured_out_assign_dut, captured_out_alwaysblock_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stimulus_gen.clk, tb, a, b, out_assign_ref, out_assign_dut, out_alwaysblock_ref, out_alwaysblock_dut );
	end

	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b );
	RefModule good1 (
		.a,
		.b,
		out_assign(out_assign_ref),
		out_alwaysblock(out_alwaysblock_ref) );
	
	TopModule top_module1 (
		a,
		b,
		out_assign(out_assign_dut),
		out_alwaysblock(out_alwaysblock_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end	task
	
	
	// State tracking initialization
	initial begin
		stats1.errors = 0;
		stats1.errortime = 0;
		stats1.errors_out_assign = 0;
		stats1.errortime_out_assign = 0;
		stats1.errors_out_alwaysblock = 0;
		stats1.errortime_out_alwaysblock = 0;
		stats1.clocks = 0;
	end

	
	// Verification: Simplifies to direct equality check
	assign tb_match = ( { out_assign_ref, out_alwaysblock_ref } === { out_assign_dut, out_alwaysblock_dut } );
	
	// Original error counting logic
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Out_assign check (Simplified comparison to maintain structure)
		if (out_assign_ref !== out_assign_dut)
		begin 
			if (stats1.errors_out_assign == 0) stats1.errortime_out_assign = $time;
			sstats1.errors_out_assign = stats1.errors_out_assign+1'b1;
		end
		
		// Out_alwaysblock check (Simplified comparison to maintain structure)
		if (out_alwaysblock_ref !== out_alwaysblock_dut)
		begin 
			if (stats1.errors_out_alwaysblock == 0) stats1.errortime_out_alwaysblock = $time;
			sstats1.errors_out_alwaysblock = stats1.errors_out_alwaysblock+1'b1;
		end
	end

	// Capture state when the FIRST error occurs (stats1.errors transitions to 1)
	always @(posedge clk, negedge clk)
	begin
		if (stats1.errors == 1 && stats1.clocks > 0) begin
			captured_a <= a;
			captured_b <= b;
			captured_out_assign_ref <= out_assign_ref;
			captured_out_alwaysblock_ref <= out_alwaysblock_ref;
			captured_out_assign_dut <= out_assign_dut;
			captured_out_alwaysblock_dut <= out_alwaysblock_dut;
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final reporting block - IMPROVED
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("--- First Mismatch Details (Time: %0d) ---", stats1.errortime);
			$display("Inputs: a = %b, b = %b", captured_a, captured_b);
			$display("Expected Outputs: out_assign = %b, out_alwaysblock = %b", captured_out_assign_ref, captured_out_alwaysblock_ref);
			$display("Actual Outputs: out_assign = %b, out_alwaysblock = %b", captured_out_assign_dut, captured_out_alwaysblock_dut);
		end
	end

endmodule