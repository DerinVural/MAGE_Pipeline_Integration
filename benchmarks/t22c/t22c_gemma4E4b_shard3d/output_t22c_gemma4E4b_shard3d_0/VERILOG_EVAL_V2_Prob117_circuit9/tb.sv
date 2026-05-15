`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic a,
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
		a <= 1;
		@(negedge clk) {a} <= 1;
		@(negedge clk) wavedrom_start("Unknown circuit");
			repeat(2) @(posedge clk);
			@(posedge clk) {a} <= 0;
			repeat(11) @(posedge clk);
			@(negedge clk) a <= 1;
			repeat(5) @(posedge clk, negedge clk);
			a <= 0;
			repeat(4) @(posedge clk);
		wavedrom_stop();

		repeat(200) @(posedge clk, negedge clk)
		a <= &((5)'($urandom));
		$finish;
	end

dendmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
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
	logic [2:0] q_ref;
	logic [2:0] q_dut;

	// Variables to capture first mismatch details
	time first_mismatch_time = 0;
	logic [2:0] first_q_ref_val = 3'b0;
	logic [2:0] first_q_dut_val = 3'b0;
	logic [1:0] first_a_val = 2'b00;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,a,q_ref,q_dut );
	end

	
	wire tb_match;	// Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a );
	RefModule good1 (
		.clk,
		a,
		.q(q_ref) );
	
	TopModule top_module1 (
		.clk,
		a,
		.q(q_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
			$display("Simulation finished at %0d ps", $time);
		end
		else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			
			// Display input signals (clk, a) and output signals (q_dut, q_ref) at first mismatch
			$display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
			
			// Clock state at mismatch
			// Displaying clk as binary since its width is 1
			$display("Input clk: %b (Binary: %b)", clk, clk);
			// Displaying a as binary since its width is 1
			$display("Input a: %b (Binary: %b)", a, a);
			// Displaying q_ref (3 bits) in HEX and BINARY
			$display("Expected q_ref: %0d (Hex: %h, Binary: %b)", q_ref, q_ref, q_ref);
			// Displaying q_dut (3 bits) in HEX and BINARY
			$display("Actual q_dut: %0d (Hex: %h, Binary: %b)", q_dut, q_dut, q_dut);
			$display("------------------------------------------");
		end
		
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		end
		
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			sstats1.errors_q = stats1.errors_q+1'b1; 
		end
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule


// Mock modules required by the golden testbench for compilation
module RefModule (input logic clk, input logic a, output logic [2:0] q);
	// Placeholder implementation to allow testbench to compile
	assign q = 3'b0;
endmodule


// Mock TopModule implementation based on the derived logic from the specification trace
module TopModule (input logic clk, input logic a, output logic [2:0] q);
	reg [2:0] q_reg = 3'b100; // Initial state observed at T=5ns is 4
	
	// Sequential logic triggered by positive clock edge
	always @(posedge clk)
	begin
		if (a == 1'b1)
		begin
			// Hold state if a is high
			q_reg <= q_reg;
		end
		else begin // a == 0
			// Increment state if a is low
			if (q_reg == 3'b110) // If current state is 6
			begin
				q_reg <= 3'b000; // Wrap to 0
			end
			else
			begin
				q_reg <= q_reg + 1'b1;
			end
			end
		end
	end
	
	// Assign the registered output to the port
	assign q = q_reg;
	endmodule