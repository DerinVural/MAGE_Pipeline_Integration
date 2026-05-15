`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] in,
	output logic reset
);

	initial begin
		repeat(200) @(negedge clk) begin
			in <= $random;
		reset <= !($random & 31);
		end
		reset <= 1'b0;
		in <= '0;
		repeat(10) @(posedge clk);
		
		repeat(200) begin
		in <= $random;
		in[3] <= 1'b1;
		@(posedge clk);
		in <= $random;
		@(posedge clk);
		in <= $random;
		@(posedge clk);
		end
		
		#1 $finish;
	end
	endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_out_bytes;
		int errortime_out_bytes;
		int errors_done;
		int errortime_done;
		int clocks;
	} stats;
	
	stats stats1;
	
	// Variables to capture first mismatch details
	logic [7:0] first_mismatch_in;
	logic first_mismatch_reset;
	logic [23:0] first_mismatch_out_bytes_dut;
	logic first_mismatch_done_dut;
	logic [23:0] first_mismatch_out_bytes_ref;
	logic first_mismatch_done_ref;
	integer first_mismatch_time = -1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;
	end

	logic [7:0] in;
	logic reset;
	logic [23:0] out_bytes_ref;
	logic [23:0] out_bytes_dut;
	logic done_ref;
	logic done_dut;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,in,reset,out_bytes_ref,out_bytes_dut,done_ref,done_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk, 
		in, 
		.reset );
	RefModule good1 (
		.clk, 
		in, 
		.reset, 
		out_bytes(out_bytes_ref), 
		done(done_ref) );
	
	TopModule top_module1 (
		.clk, 
		in, 
		.reset, 
		out_bytes(out_bytes_dut), 
		done(done_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_bytes_ref, done_ref } === ( { out_bytes_ref, done_ref } ^ { out_bytes_dut, done_dut } ^ { out_bytes_ref, done_ref } ) );
	
	always @(posedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Error checking for out_bytes
		if (out_bytes_ref !== ( out_bytes_ref ^ out_bytes_dut ^ out_bytes_ref ))
		begin 
			if (stats1.errors_out_bytes == 0) stats1.errortime_out_bytes = $time;
			sstats1.errors_out_bytes = stats1.errors_out_bytes+1'b1; 
		end
		
		// Error checking for done
		if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
		begin 
			if (stats1.errors_done == 0) stats1.errortime_done = $time;
			sstats1.errors_done = stats1.errors_done+1'b1; 
		end
	end

	// Capture state ONLY on the FIRST mismatch
	always @(posedge clk) begin
		if (stats1.errors == 1 && tb_mismatch) begin
			first_mismatch_time = $time;
			first_mismatch_in = in;
			first_mismatch_reset = reset;
			first_mismatch_out_bytes_dut = out_bytes_dut;
			first_mismatch_done_dut = done_dut;
			first_mismatch_out_bytes_ref = out_bytes_ref;
			first_mismatch_done_ref = done_ref;
		end
	end

	// Timeout mechanism
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final report
	final begin
		if (stats1.errors == 0)
			$display("SIMULATION PASSED");
		else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("-----------------------------------------------------------------");
			$display("--- First Mismatch Details (Time: %0d ps) ---", first_mismatch_time);
			$display("Input Signals:");
			$display("  clk: %b", clk);
			$display("  reset: %b", first_mismatch_reset);
			$display("  in: HEX=%h, BIN=%b", first_mismatch_in, first_mismatch_in);
			$display("Output Signals (DUT vs REF):");
			$display("  done_dut: HEX=%h, BIN=%b | done_ref: HEX=%h, BIN=%b", first_mismatch_done_dut, first_mismatch_done_dut, first_mismatch_done_ref, first_mismatch_done_ref);
			$display("  out_bytes_dut: HEX=%h, BIN=%b | out_bytes_ref: HEX=%h, BIN=%b", first_mismatch_out_bytes_dut, first_mismatch_out_bytes_dut, first_mismatch_out_bytes_ref, first_mismatch_out_bytes_ref);
			$display("-----------------------------------------------------------------");
			$display("Detailed Error Counts:");
			$display("  Total Errors: %0d / %0d cycles", stats1.errors, stats1.clocks);
			$display("  out_bytes Errors: %0d (First @ %0d ps)", stats1.errors_out_bytes, stats1.errortime_out_bytes);
			$display("  done Errors: %0d (First @ %0d ps)", stats1.errors_done, stats1.errortime_done);
			$display("=================================================================");
		end

endmodule

// Dummy module definitions required by the golden testbench structure
module RefModule (
	input clk,
	input [7:0] in,
	input reset,
	output logic [23:0] out_bytes,
	output logic done
);
	// In a real scenario, this would be the golden reference model. 
	// For simulation compilation, we make it pass everything.
	always @(posedge clk) begin
		if (reset) begin
			done <= 1'b0;
			out_bytes <= 24'h0;
		end
		// Placeholder logic to allow simulation to run
		done <= 1'b0;
		out_bytes <= 24'h0;
	end
endmodule

module TopModule (
	input clk,
	input reset,
	input [7:0] in,
	output logic [23:0] out_bytes,
	output logic done
);
	// The DUT we are testing. Minimal placeholder logic.
	always @(posedge clk) begin
		if (reset) begin
		done <= 1'b0;
		out_bytes <= 24'h0;
	end
		// Placeholder logic
		done <= 1'b0;
		out_bytes <= 24'h0;
end
endmodule