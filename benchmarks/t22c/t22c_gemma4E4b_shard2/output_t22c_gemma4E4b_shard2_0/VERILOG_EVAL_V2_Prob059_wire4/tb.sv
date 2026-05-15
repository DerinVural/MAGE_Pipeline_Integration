`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
		input clk,
		output logic a, b, c,
		output reg[511:0] wavedrom_title,
		output reg wavedrom_enable
);


		task wavedrom_start(input[511:0] title = "");
	endtask
	
		task wavedrom_stop;
		#1;
	endtask	

		always @(posedge clk, negedge clk)
			{a,b,c} <= $random;
		
		initial begin
			@(negedge clk) wavedrom_start();
			repeat(8) @(posedge clk);
			@(negedge clk) wavedrom_stop();
			repeat(100) @(negedge clk);
			$finish;
		end
	endmodule

module tb();
		typedef struct packed {
			int errors;
			int errortime;
			int errors_w;
			int errortime_w;
			int errors_x;
			int errortime_x;
			int errors_y;
			int errortime_y;
			int errors_z;
			int errortime_z;
			int clocks;
		
			// Storage for first mismatch details
			logic s_a, s_b, s_c; // Inputs at first mismatch
			logic s_w_ref, s_x_ref, s_y_ref, s_z_ref; // Expected outputs
			logic s_w_dut, s_x_dut, s_y_dut, s_z_dut; // Actual outputs
		} stats;
		
		stats stats1;
		
		
		wire[511:0] wavedrom_title;
		wire wavedrom_enable;
		int wavedrom_hide_after_time;
		
		reg clk=0;
		initial forever
			#5 clk = ~clk;

		logic a;
		logic b;
		logic c;
		logic w_ref;
		logic w_dut;
		logic x_ref;
		logic x_dut;
		logic y_ref;
		logic y_dut;
		logic z_ref;
		logic z_dut;

		// State storage for detailed reporting
		logic first_mismatch_detected = 0;
		
		initial begin 
			dumpfile("wave.vcd");
			dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,w_ref,w_dut,x_ref,x_dut,y_ref,y_dut,z_ref,z_dut );
		end

		wire tb_match;
		wire tb_mismatch = ~tb_match;
		
		stimulus_gen stim1 (
			.clk,
			.* ,
			.a,
			.b,
			.c );
		RefModule good1 (
			.a,
			.b,
			.c,
			.w(w_ref),
			.x(x_ref),
			.y(y_ref),
			.z(z_ref) );
		
		TopModule top_module1 (
			.a,
			.b,
			.c,
			.w(w_dut),
			.x(x_dut),
			.y(y_dut),
			.z(z_dut) );

		
		bit strobe = 0;
		task wait_for_end_of_timestep;
			repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
			end
		endtask	

		// --- Mismatch Reporting Logic ---
		initial begin
			// Wait for initial setup to settle
			repeat(10) @(posedge clk);
			$display("
============================================================");
			$display("Starting simulation verification...");
			$display("============================================================");
		end

		// Verification assignment
		assign tb_match = ( { w_ref, x_ref, y_ref, z_ref } === ( { w_ref, x_ref, y_ref, z_ref } ^ { w_dut, x_dut, y_dut, z_dut } ^ { w_ref, x_ref, y_ref, z_ref } ) );
		
		// Main Clocked Comparison Loop
		always @(posedge clk, negedge clk) begin

			// 1. Clock count
			stats1.clocks++;

			// 2. Total mismatch tracking
			if (!tb_match) begin
				if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
			// Store current state if this is the absolute first mismatch
			if (stats1.errors == 1) begin
				s_a = a; s_b = b; s_c = c;
				s_w_ref = w_ref; s_x_ref = x_ref; s_y_ref = y_ref; s_z_ref = z_ref;
				s_w_dut = w_dut; s_x_dut = x_dut; s_y_dut = y_dut; s_z_dut = z_dut;
			end
			endif
			end

			// 3. Individual signal mismatch tracking and first error recording
			if (w_ref !== w_dut) begin
				if (stats1.errors_w == 0) stats1.errortime_w = $time;
			stats1.errors_w = stats1.errors_w+1'b1;
			end
			if (x_ref !== x_dut) begin
				if (stats1.errors_x == 0) stats1.errortime_x = $time;
			stats1.errors_x = stats1.errors_x+1'b1;
			end
			if (y_ref !== y_dut) begin
				if (stats1.errors_y == 0) stats1.errortime_y = $time;
			stats1.errors_y = stats1.errors_y+1'b1;
			end
			if (z_ref !== z_dut) begin
				if (stats1.errors_z == 0) stats1.errortime_z = $time;
			stats1.errors_z = stats1.errors_z+1'b1;
			end
			end
		end

		// Timeout
		initial begin
			#1000000
			$display("
--- TIMEOUT REACHED ---
");
			$finish();
		end

		// Final Reporting Block
		initial begin
			@(negedge clk);
			#10;
			$display("
============================================================");
			$display("SIMULATION SUMMARY");
			$display("============================================================");
			
			if (stats1.errors == 0) begin
				s$display("SIMULATION PASSED");
			end else begin
				s$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
				$display("
--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
				// Inputs
				s$display("Inputs (a, b, c): %b, %b, %b", s_a, s_b, s_c);
				// Expected Outputs
				s$display("Expected Outputs (w, x, y, z): %b, %b, %b, %b", s_w_ref, s_x_ref, s_y_ref, s_z_ref);
				// Actual Outputs
				s$display("Actual Outputs (w, x, y, z): %b, %b, %b, %b", s_w_dut, s_x_dut, s_y_dut, s_z_dut);
			end
			
			// Retaining original individual error reporting (as per original structure, though the prompt implies the main failure message is primary)
			if (stats1.errors_w) $display("Output 'w' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_w, stats1.errortime_w);
			if (stats1.errors_x) $display("Output 'x' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_x, stats1.errortime_x);
			if (stats1.errors_y) $display("Output 'y' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_y, stats1.errortime_y);
			if (stats1.errors_z) $display("Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
			
			$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
			$display("Simulation finished at %0d ps", $time);
			$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		end


endmodule