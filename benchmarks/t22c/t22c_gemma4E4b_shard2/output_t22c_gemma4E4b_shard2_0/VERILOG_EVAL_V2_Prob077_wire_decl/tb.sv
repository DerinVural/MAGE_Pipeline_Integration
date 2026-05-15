`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// hdlbits_prop {len: 5}


module stimulus_gen (
	input clk,
	output reg a,b,c,d,
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
		{a,b,c,d} = 4'h0;
		@(negedge clk);
		wavedrom_start("Exhaustive test");
		repeat(20) @(posedge clk, negedge clk)
			{d,c,b,a} <= {d,c,b,a} + 1'b1;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk) begin
			{a,b,c,d} <= $random;
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
		int errors_out_n;
		int errortime_out_n;

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
logic b;
logic c;
logic d;
logic out_ref;
logic out_dut;
logic out_n_ref;
logic out_n_dut;


initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,out_ref,out_dut,out_n_ref,out_n_dut );
	end


wire tb_match;		// Verification
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.* , // Matches wavedrom_title and wavedrom_enable
		.a,
		.b,
		.c,
		.d );
RefModule good1 (
		.a,
		.b,
		.c,
		.d,
		.out(out_ref),
		.out_n(out_n_ref) );

TopModule top_module1 (
		a,
		b,
		c,
		d,
		out(out_dut),
		out_n(out_n_dut) );



bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	


final begin
		// Original hints removed, replaced with final required reporting
		end
	

// Helper task for displaying signals in HEX/BIN format
task display_signals(string label);
		$display("\n======================================================");
		$display("*** FIRST MISMATCH DETECTED for %s ***", label);
		$display("Time: %0d ps", $time);
		$display("------------------------------------------------------");
		$display("Inputs: a=%b, b=%b, c=%b, d=%b", a, b, c, d);
		$display("Reference Outputs: out_ref=%b, out_n_ref=%b", out_ref, out_n_ref);
		$display("DUT Outputs: out_dut=%b, out_n_dut=%b", out_dut, out_n_dut);
		$display("======================================================");
	endtask



	initial begin
		// Wait for initial transient period to settle (optional but good practice)
		@(posedge clk);
		
		// Wait for stimulus generation to run its course before final checks
		@(negedge clk);
		end


	// Verification logic
assign tb_match = ( { out_ref, out_n_ref } === ( { out_dut, out_n_dut } ^ { out_ref, out_n_ref } ^ { out_ref, out_n_ref } ) );

// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
			end
		
		// Check for 'out' mismatch
		if (out_ref !== out_dut) begin
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			sstats1.errors_out = stats1.errors_out+1'b1;
			if (stats1.errors_out == 1) display_signals("out"); // Display on first error
		end
		
		// Check for 'out_n' mismatch
		if (out_n_ref !== out_n_dut) begin
			if (stats1.errors_out_n == 0) stats1.errortime_out_n = $time;
			sstats1.errors_out_n = stats1.errors_out_n+1'b1;
			if (stats1.errors_out_n == 1) display_signals("out_n"); // Display on first error
		end
	end

// add timeout after 100K cycles
initial begin
	#1000000
	$display("TIMEOUT");
	$finish();
end


// Final reporting logic based on requirements
initial begin
	// Wait a short time after stimulus_gen finishes its random phase
	#100;
	
	if (stats1.errors == 0 && stats1.errors_out == 0 && stats1.errors_out_n == 0) begin
		$display("\n\n=========================================");
		$display("SIMULATION PASSED");
		$display("=========================================");
		$finish;
	end else begin
		int total_mismatches = stats1.errors;
		int first_mismatch_time = stats1.errortime;
		$display("\n\n=========================================");
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_mismatch_time);
		$display("=========================================");
		$finish;
	end
end

endmodule

// Dummy modules required for compilation based on golden testbench structure
module RefModule (input a, input b, input c, input d, output out, output out_n); endmodule

module TopModule (
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n
);

    // Intermediate wires as requested
    wire and_ab_out;
    wire and_cd_out;

    // Layer 1: AND gates
    assign and_ab_out = a & b;
    assign and_cd_out = c & d;

    // Layer 2: OR gate to 'out'
    assign out = and_ab_out | and_cd_out;

    // Inverted output 'out_n'
    assign out_n = ~out;

endmodule
