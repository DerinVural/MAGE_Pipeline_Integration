`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
		input clk,
		input tb_match,
		output logic [3:0] in,
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
		in <= 4'h3;
		@(negedge clk);
		wavedrom_start();
			@(posedge clk) in <= 3;
			@(posedge clk) in <= 6;
			@(posedge clk) in <= 12;
			@(posedge clk) in <= 9;
			@(posedge clk) in <= 5;
		@(negedge clk);
		wavedrom_stop();
		in <= $random;
		repeat(100) begin
		@(negedge clk) in <= $random;
		@(posedge clk) in <= $random;
		end
		h#1 $finish;
	end
	endmodule

module RefModule (
    input  logic [3:0] in,
    output logic [3:0] out_both,
    output logic [3:0] out_any,
    output logic [3:0] out_different
);

    // (1) out_both: in[i] AND in[i+1] (i+1 is higher index)
    assign out_both[3] = 1'b0; // No left neighbor for in[3]
    assign out_both[2] = in[2] & in[3]; // in[2] & in[3]
    assign out_both[1] = in[1] & in[2]; // in[1] & in[2]
    assign out_both[0] = in[0] & in[1]; // in[0] & in[1]

    // (2) out_any: in[i] OR in[i-1] (i-1 is lower index)
    assign out_any[0] = in[0] | 1'b0; // No right neighbor for in[0]
    assign out_any[1] = in[1] | in[0]; // in[1] | in[0]
    assign out_any[2] = in[2] | in[1]; // in[2] | in[1]
    assign out_any[3] = in[3] | in[2]; // in[3] | in[2]

    // (3) out_different: in[i] != in[i+1] (wrapping for i=3 -> in[0])
    assign out_different[0] = in[0] ^ in[1]; // in[0] != in[1]
    assign out_different[1] = in[1] ^ in[2]; // in[1] != in[2]
    assign out_different[2] = in[2] ^ in[3]; // in[2] != in[3]
    assign out_different[3] = in[3] ^ in[0]; // in[3] != in[0] (wrapping)

endmodule

module tb();

		typedef struct packed {
		int errors;
		int errortime;
		int errors_out_both;
		int errortime_out_both;
		int errors_out_any;
		int errortime_out_any;
		int errors_out_different;
		int errortime_out_different;

		int clocks;
		logic [3:0] in_at_error;
		logic [3:0] out_both_dut_at_error;
		logic [3:0] out_any_dut_at_error;
		logic [3:0] out_different_dut_at_error;
		logic [3:0] out_both_ref_at_error;
		logic [3:0] out_any_ref_at_error;
		logic [3:0] out_different_ref_at_error;
	} stats;
		
	stats stats1;
		
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;
	end

	logic [3:0] in;
	logic [3:0] out_both_ref;
	logic [3:0] out_both_dut;
	logic [3:0] out_any_ref;
	logic [3:0] out_any_dut;
	logic [3:0] out_different_ref;
	logic [3:0] out_different_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_both_ref,out_both_dut,out_any_ref,out_any_dut,out_different_ref,out_different_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		in );
	RefModule good1 (
		in,
		out_both(out_both_ref),
		out_any(out_any_ref),
		out_different(out_different_ref) );
	
	TopModule top_module1 (
		in,
		out_both(out_both_dut),
		out_any(out_any_dut),
		out_different(out_different_dut) );

	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
	// Capture signals on FIRST mismatch
	always @(posedge clk, negedge clk) begin
		if (stats1.clocks == 0) begin
			stats1.clocks <= 1'b1;
		end

		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			s
			stats1.errors++;
			
			// Capture signals ONLY on the very first error
			if (stats1.errors == 1) begin
				sstats1.in_at_error = in;
			sstats1.out_both_dut_at_error = out_both_dut;
			sstats1.out_any_dut_at_error = out_any_dut;
			sstats1.out_different_dut_at_error = out_different_dut;
			sstats1.out_both_ref_at_error = out_both_ref;
			sstats1.out_any_ref_at_error = out_any_ref;
			sstats1.out_different_ref_at_error = out_different_ref;
			end
			end
		
		// Original error counting logic (Preserved)
		if (out_both_ref !== ( out_both_ref ^ out_both_dut ^ out_both_ref ))
		begin if (stats1.errors_out_both == 0) stats1.errortime_out_both = $time;
			sstats1.errors_out_both = stats1.errors_out_both+1'b1; end
		if (out_any_ref !== ( out_any_ref ^ out_any_dut ^ out_any_ref ))
		begin if (stats1.errors_out_any == 0) stats1.errortime_out_any = $time;
			sstats1.errors_out_any = stats1.errors_out_any+1'b1; end
		if (out_different_ref !== ( out_different_ref ^ out_different_dut ^ out_different_ref ))
		begin if (stats1.errors_out_different == 0) stats1.errortime_out_different = $time;
			sstats1.errors_out_different = stats1.errors_out_different+1'b1; end
		end

		// This assignment must be done outside the always block to reflect the state at the end of the clock cycle/after sampling
		tb_match = ( { out_both_ref, out_any_ref, out_different_ref } === ( { out_both_ref, out_any_ref, out_different_ref } ^ { out_both_dut, out_any_dut, out_different_dut } ^ { out_both_ref, out_any_ref, out_different_ref } ) );
	end

	// --- Final Reporting Logic --- 
	initial begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
			end
		
		if (stats1.errors > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("======================================================================================================