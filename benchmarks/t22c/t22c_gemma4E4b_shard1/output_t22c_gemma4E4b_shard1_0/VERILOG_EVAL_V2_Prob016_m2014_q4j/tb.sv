`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic [3:0] x,
	output logic [3:0] y
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{x,y} <= $random;
		end
		
		#1 $finish;
	end
endmodule

module tb();
	
typedef struct packed {
		int errors;
		int errortime;
		int errors_sum;
		int errortime_sum;
		int clocks;
	} stats;
	
stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
reg clk=0;
initial forever
		#5 clk = ~clk;

logic [3:0] x;
logic [3:0] y;
logic [4:0] sum_ref; // Expected output
logic [4:0] sum_dut; // DUT output

reg first_mismatch_detected = 0;

initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,x,y,sum_ref,sum_dut );
end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk, 
		x, 
		y );
	
// Instantiate Reference Model (Golden)
RefModule good1 (
		.x, 
		y, 
		sum(sum_ref) );
	
// Instantiate DUT
TopModule top_module1 (
		.x, 
		y, 
		sum(sum_dut) );


bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask


// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { sum_ref } === ( { sum_ref } ^ { sum_dut } ^ { sum_ref } ) );

// Clocked logic block for counting and detailed logging
always @(posedge clk, negedge clk) begin
		stats1.clocks++;

		// Original error counting logic
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
		end

		// Original sum error counting logic (retained for fidelity)
		if (sum_ref !== ( sum_ref ^ sum_dut ^ sum_ref ))
		begin 
			if (stats1.errors_sum == 0) stats1.errortime_sum = $time;
			sstats1.errors_sum = stats1.errors_sum+1'b1; 
		end
	end

		// NEW: Detailed Mismatch Reporting on first error
		if (!tb_match && stats1.errors == 1 && !first_mismatch_detected) begin
			$display("
===================================================");
			$display("!!! FIRST MISMATCH DETECTED !!!");
			$display("Time: %0t ps", $time);
			$display("----------------------------------------------------");
			// Display inputs and outputs in HEX and BIN format (width <= 64 check is implicitly handled by SystemVerilog format specifiers for these small signals)
			$display("Input x:  HEX=%h, BIN=%b", x, x);
			$display("Input y:  HEX=%h, BIN=%b", y, y);
			display("DUT Sum:  HEX=%h, BIN=%b", sum_dut, sum_dut);
			$display("Expected Sum: HEX=%h, BIN=%b", sum_ref, sum_ref);
			$display("====================================================");
			first_mismatch_detected = 1;
		end
	end

// Final reporting block
final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
		$display("Final statistics: Total Clocks=%0d, Total Mismatches=%0d", stats1.clocks, stats1.errors);
		$finish();
end

// add timeout after 100K cycles
initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
end

endmodule

// Placeholder modules required by golden testbench for compilation
module RefModule (
	input logic [3:0] x,
	input logic [3:0] y,
	output logic [4:0] sum
);
	// Assume RefModule implements the correct adder logic for testing purposes
endmodule

module TopModule (
	input logic [3:0] x,
	input logic [3:0] y,
	output logic [4:0] sum
);
	// Implementation matching specification: 4-bit adder with overflow in 5-bit sum.
	// SystemVerilog addition handles the carry correctly into the 5th bit.
	assign sum = x + y;
endmodule