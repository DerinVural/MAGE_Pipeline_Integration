`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Golden Testbench Structure Preservation
module stimulus_gen (
		input clk,
		output logic x,
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
		x <= 0;
		@(negedge clk) wavedrom_start();
		@(posedge clk) x <= 2'h0;
		@(posedge clk) x <= 2'h0;
		@(posedge clk) x <= 2'h0;
		@(posedge clk) x <= 2'h0;
		@(posedge clk) x <= 2'h1;
		@(posedge clk) x <= 2'h1;
		@(posedge clk) x <= 2'h1;
		@(posedge clk) x <= 2'h1;
		@(negedge clk) wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
		x <= $random;

		$finish;
	end
		endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_z;
		int errortime_z;
		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic x;
	logic z_ref;
	logic z_dut;

	// Variables to hold state at first mismatch for detailed display
	logic [511:0] first_x_val = 0;
	logic first_z_dut_val = 0;
	logic first_z_ref_val = 0;
	int first_mismatch_time = -1;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,x,z_ref,z_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.*,
		.x 
	);
	RefModule good1 (
		.clk,
		.x,
		z(z_ref) );
	
	TopModule top_module1 (
		.clk,
		x,
		z(z_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	endtask
	
	
	final begin
		// Check for any errors recorded
		if (stats1.errors == 0 && stats1.errors_z == 0) begin
			$display("SIMULATION PASSED");
			end
		else begin
			// SIMULATION FAILED: Display required failure message
			$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
			
			// Detailed display of first mismatch (as required)
			$display("\n--- First Mismatch Details (Time %0d ps) ---", stats1.errortime);
			
			// 1. Input Signals
			$display("Input Signals at First Mismatch:");
			$display("  clk: %b", clk);
			// Display x in BIN and HEX
			$display("  x: %b (Hex: 0x%h)", x, x);
			
			// 2. Output Signals (DUT vs Reference/Expected)
			$display("Output Signals at First Mismatch:");
			// Display Z_DUT (Actual)
			$display("  Z_DUT (Actual): %b (Hex: 0x%h)", z_dut, z_dut);
			// Display Z_REF (Expected)
			$display("  Z_REF (Expected): %b (Hex: 0x%h)", z_ref, z_ref);
			$display("------------------------------------------");
			end
	end
	
	// Verification check as per golden testbench
	assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
	
	// Logic to track errors and capture first mismatch state
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		// Check for primary mismatch (tb_match)
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			// Capture state at first error
			first_mismatch_time = $time;
			first_x_val = x;
			first_z_dut_val = z_dut;
			first_z_ref_val = z_ref;
			end
			sstats1.errors++; // Corrected typo from previous version
		end
		
		// Check for secondary mismatch (z_ref vs derived value)
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin 
			if (stats1.errors_z == 0) stats1.errortime_z = $time;
			sstats1.errors_z = stats1.errors_z+1'b1; // Corrected typo from previous version
		end
	end

	// Add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule