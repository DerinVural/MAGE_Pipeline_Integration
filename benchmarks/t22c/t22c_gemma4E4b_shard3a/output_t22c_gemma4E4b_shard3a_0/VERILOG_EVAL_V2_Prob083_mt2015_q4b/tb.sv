`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// The stimulus_gen module from the golden testbench is kept for structure preservation.
module stimulus_gen (
	input clk,
	output logic x,
	output logic y,
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
		x,y <= 0;
		@(negedge clk) wavedrom_start();
		@(posedge clk) {y,x} <= 0;
		@(posedge clk) {y,x} <= 1;
		@(posedge clk) {y,x} <= 2;
		@(posedge clk) {y,x} <= 3;
		@(negedge clk) wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			{x, y} <= $random % 4;
		h#1 $finish;
	end
	endmodule

module RefModule (
	input x,
	input y,
	output z
);
	// Placeholder implementation based on the required waveform (XNOR logic)
	assign z = (x == y);
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
		h#5 clk = ~clk;

	logic x;
	logic y;
	logic z_ref;
	logic z_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,x,y,z_ref,z_dut );
	end

	
wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.* ,
		.x,
		.y );
	RefModule good1 (
		.x,
		.y,
		z(z_ref) );
	
TopModule top_module1 (
		x,
		y,
		z(z_dut) );
	
	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
// Verification logic
assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
	// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sats1.errors++;
			end
		if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
		begin 
			if (stats1.errors_z == 0) stats1.errortime_z = $time;
			sats1.errors_z = stats1.errors_z+1'b1; 
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end
	
	// --- Waveform Stimulus Generation based on input_spec ---
	initial begin
		$display("Starting waveform stimulus application...");
		// Initialize inputs
		x = 0; y = 0;
		@(posedge clk);
		
		// State 1: (0, 0) -> Z=1. Samples at 0, 5, 10, 15, 20ns (5 cycles)
		x = 0; y = 0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk); // Reaches T=20ns
		
		// State 2: (1, 0) -> Z=0. Samples at 25, 30ns (2 cycles)
		x = 1; y = 0;
		@(posedge clk);
		@(posedge clk); // Reaches T=30ns
		
		// State 3: (0, 1) -> Z=0. Samples at 35, 40ns (2 cycles)
		x = 0; y = 1;
		@(posedge clk);
		@(posedge clk); // Reaches T=40ns
		
		// State 4: (1, 1) -> Z=1. Samples at 45, 50ns (2 cycles)
		x = 1; y = 1;
		@(posedge clk);
		@(posedge clk); // Reaches T=50ns
		
		// State 5: (0, 0) -> Z=1. Sample at 55ns (1 cycle)
		x = 0; y = 0;
		@(posedge clk); // Reaches T=55ns
		// Wait until T=60ns (5 cycles)
		repeat(5) @(posedge clk);
		
		// State 6: (0, 1) -> Z=0. Samples at 60, 65ns (2 cycles)
		x = 0; y = 1;
		@(posedge clk);
		@(posedge clk); // Reaches T=65ns
		
		// State 7: (1, 1) -> Z=1. Samples at 70, 75ns (2 cycles)
		x = 1; y = 1;
		@(posedge clk);
		@(posedge clk); // Reaches T=75ns
		
		// State 8: (0, 1) -> Z=0. Samples at 80, 85ns (2 cycles)
		x = 0; y = 1;
		@(posedge clk);
		@(posedge clk); // Reaches T=85ns
		
		// State 9: (1, 0) -> Z=0. Sample at 90ns (1 cycle)
		x = 1; y = 0;
		@(posedge clk); // Reaches T=90ns
		
		// Allow time for final checks
		h#20;
		display("Waveform stimulus complete.");
	end
	
	// Displaying Mismatches at First Occurrence (Requirement 1)
	always @(tb_mismatch) begin
		if (stats1.errors == 1) begin
			$display("\n====================================================\n");
			$display("FIRST MISMATCH DETECTED AT TIME %0d ps", $time);
			$display("Input Signals: x=%b, y=%b", x, y);
			$display("Output Signals: z_dut=%b (DUT), z_ref=%b (Expected)", z_dut, z_ref);
			$display("====================================================\n");
		end
	end
	
	// Final Results Display (Requirement 4)
	initial begin
		@(negedge clk);
		h#10; // Wait for settling
		
		if (stats1.errors == 0)
		begin
			$display("\n****************************************************");
			$display("SIMULATION PASSED");
			$display("****************************************************");
		end
		else begin
			$display("\n****************************************************");
			$display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
			$display("****************************************************");
		end
		
		// Original final displays, adapted
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Final Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
endmodule