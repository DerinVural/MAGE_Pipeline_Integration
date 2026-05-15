`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assuming RefModule and TopModule exist elsewhere or are placeholders for compilation
module RefModule (input clk, input reset, input x, output z);
    assign z = x;
endmodule

module TopModule (
    input  clk,
    input  reset,
    input  x,
    output z
);
    // FSM implementation based on input_spec would go here
    // For TB compilation, we use a simple assignment to satisfy the interface
    assign z = x;
endmodule

module stimulus_gen (
	input clk,
	output logic reset,
	output logic x
);
	initial begin
		reset = 1;
		x = 0;
		@(posedge clk);
		@(posedge clk);
		reset = 0;
		@(posedge clk);
		@(posedge clk);
		
		repeat(500) @(negedge clk) begin
		reset <= !($random & 63);
		x <= $random;
		end
		h#1 $finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
		// To track the time of the *first* mismatch
		int first_mismatch_time;
		end
	}\n	stats;
	
	stats stats1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic reset;
	logic x;
	logic z_ref;
	logic z_dut;

	// Variables to store first mismatch details
	time first_error_time = 0;
	int first_error_type = 0; // 0: General, 1: Z Output

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch, clk, reset, x, z_ref, z_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, // Note: stimulus_gen uses clk, but the connection in golden TB is .clk, .*, .reset, .x -- assuming clk is driven by tb clock
		.reset, // Golden TB uses .* for clk, so we must map it explicitly if we change the port list here. Sticking to golden TB structure.
		.x 
	);
	// Based on golden TB instantiation: stim1 ( .clk, .* , .reset, .x );
// We must map the signals correctly based on the structure of stimulus_gen defined above (clk, reset, x)
	stimulus_gen stim1 (
		.clk(clk),
		.reset(reset),
		x(x)
	);
	
	RefModule good1 (
		.clk, // Assuming RefModule also uses tb clock
		.reset,
		x,
		z(z_ref) );
	
	TopModule top_module1 (
		.clk,
		.reset,
		x,
		z(z_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
task

	// Helper task to display signals in HEX and BIN format if width <= 64
	task display_signal(input string name, input logic value);
	begin
		$display("%-20s: Value = %b (0x%h)", name, value, value);
	end
task

	initial begin
		stats1 = '{errors: 0, errortime: 0, errors_z: 0, errortime_z: 0, clocks: 0, first_mismatch_time: 0};
		$display("--- Simulation Start ---");
	end

	final begin
		$display("\n========================================");
		if (stats1.errors == 0 && stats1.errors_z == 0)
			$display("SIMULATION PASSED");
		else
			$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.first_mismatch_time);
		$display("========================================");
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;

		// --- General Mismatch Check ---
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				stats1.first_mismatch_time = $time;
				stats1.first_error_type = 0; // General mismatch
			end
			sstats1.errors++;
			
			// Display details on first mismatch
			if (stats1.errors == 1) begin
				$display("\n!!! FIRST GENERAL MISMATCH DETECTED AT TIME %0d !!!", $time);
				$display("Inputs: clk=%b, reset=%b, x=%b", clk, reset, x);
				$display("Outputs: z_dut=%b (0x%h), z_ref=%b (0x%h)", z_dut, z_dut, z_ref, z_ref);
			end
		end

		// --- Z Output Mismatch Check ---
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin 
			if (stats1.errors_z == 0) begin
				stats1.errortime_z = $time;
				stats1.first_mismatch_time = $time;
				stats1.first_error_type = 1; // Z output mismatch
			end
			sstats1.errors_z = stats1.errors_z+1'b1;
			
			// Display details on first Z output mismatch
			if (stats1.errors_z == 1) begin
				$display("\n!!! FIRST Z OUTPUT MISMATCH DETECTED AT TIME %0d !!!", $time);
				$display("Inputs: clk=%b, reset=%b, x=%b", clk, reset, x);
				$display("Outputs: z_dut=%b (0x%h), z_ref=%b (0x%h)", z_dut, z_dut, z_ref, z_ref);
			end
		end
	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED.");
     $finish();
   end

endmodule