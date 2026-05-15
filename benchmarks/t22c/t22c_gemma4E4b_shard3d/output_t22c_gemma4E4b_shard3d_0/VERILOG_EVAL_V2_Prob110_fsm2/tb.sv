`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic j, k,
	output logic areset,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);

	reg reset;
	assign areset = reset;
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
		s$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
		s$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	endtask

	// Add two ports to module stimulus_gen:
	//    output [511:0] wavedrom_title
	//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	
		
		reg [0:11][1:0] d = 24'b000101010010101111111111;
		
		initial begin
			reset <= 1;
			j <= 0;
			k <= 0;
			@(posedge clk);
			reset <= 0;
			j <= 1;
			@(posedge clk);
			j <= 0;
			wavedrom_start("Reset and transitions");
			reset_test(1);
			for (int i=0;i<12;i++)
				@(posedge clk) {k, j} <= d[i];
			wavedrom_stop();
			repeat(200) @(posedge clk, negedge clk) begin
			{j,k} <= $random;
			reset <= !($random & 7);
			end
			#1 $finish;
		end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;
		int clocks;
	} stats;
	
	stats stats1;
	
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic j;
	logic k;
	logic areset;
	logic out_ref;
	logic out_dut;

	// Variables to store first mismatch details
	logic first_mismatch_detected = 0;
	time first_mismatch_time = 0;
	logic [1:0] first_j_k_at_error = 2'b00;
	logic first_areset_at_error = 0;
	logic first_out_ref_at_error = 0;
	logic first_out_dut_at_error = 0;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,j,k,areset,out_ref,out_dut );
	end

	
	wire tb_match; // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		j,
		k,
		areset );
	RefModule good1 (
		.clk,
		j,
		k,
		areset,
		out(out_ref) );
	
	TopModule top_module1 (
		.clk,
		j,
		k,
		areset,
		out(out_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
	final begin
		if (stats1.errors_out > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			$display("--- FIRST MISMATCH DETAILS ---");
			$display("Time: %0d ps", stats1.errortime_out);
			// Displaying inputs (j, k, areset)
			$display("Inputs (j, k, areset): J=%b, K=%b, ARESET=%b", first_j_k_at_error[0], first_j_k_at_error[1], first_areset_at_error);
			// Displaying outputs (dut, ref)
			$display("Outputs (dut, ref): DUT=%b, REF=%b", first_out_dut_at_error, first_out_ref_at_error);
			$display("-----------------------------");
		end
		else begin
			$display("SIMULATION PASSED");
		end

		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Check for output mismatch
		if (out_ref !== out_dut) begin
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1;
			// Capture signals ONLY on the FIRST output mismatch
			if (stats1.errors_out == 1) begin
				first_mismatch_detected = 1;
				first_mismatch_time = $time;
				// Capture inputs (j, k, areset) from the current state (which just evaluated at this clock edge)
				first_j_k_at_error = {j, k};
				first_areset_at_error = areset;
				// Capture outputs
				first_out_ref_at_error = out_ref;
				first_out_dut_at_error = out_dut;
			end
		end
	end

	// add timeout after 100K cycles
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule