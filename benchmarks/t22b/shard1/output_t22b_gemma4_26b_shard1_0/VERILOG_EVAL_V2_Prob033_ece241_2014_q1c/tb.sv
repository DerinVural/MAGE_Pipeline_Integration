`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [7:0] a, b,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		{a, b} <= 0;
		@(negedge clk) wavedrom_start();
			@(posedge clk) {a, b} <= 16'h0;
			@(posedge clk) {a, b} <= 16'h0070;
			@(posedge clk) {a, b} <= 16'h7070;
			@(posedge clk) {a, b} <= 16'h7090;
			@(posedge clk) {a, b} <= 16'h9070;
			@(posedge clk) {a, b} <= 16'h9090;
			@(posedge clk) {a, b} <= 16'h90ff;
		@(negedge clk) wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
			{a,b} <= $random;

		$finish;
	end
	
endmodule

module RefModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] s,
    output logic       overflow
);
    logic [8:0] full_res;
    always_comb begin
        full_res = $signed(a) + $signed(b);
        s = full_res[7:0];
        overflow = (a[7] == b[7]) && (s[7] != a[7]);
    end
endmodule

module TopModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] s,
    output logic       overflow
);
    always_comb begin
        s = a + b;
        overflow = (a[7] == b[7]) && (s[7] != a[7]);
    end
endmodule

module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_s;
		int errortime_s;
		int errors_overflow;
		int errortime_overflow;

		int clocks;
	} stats;
	
	stats stats1;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		#5 clk = ~clk;

	logic [7:0] a;
	logic [7:0] b;
	logic [7:0] s_ref;
	logic [7:0] s_dut;
	logic overflow_ref;
	logic overflow_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,s_ref,s_dut,overflow_ref,overflow_dut );
	end

	wire tb_match;    // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b );
	RefModule good1 (
		.a,
		.b,
		.s(s_ref),
		.overflow(overflow_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.s(s_dut),
		.overflow(overflow_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	task report_mismatch;
		$display("Mismatch detected at time %0t:", $time);
		$display("Inputs: a=%h (%b), b=%h (%b)", a, a, b, b);
		$display("Expected: s=%h (%b), overflow=%b", s_ref, s_ref, overflow_ref);
		$display("Actual:   s=%h (%b), overflow=%b", s_dut, s_dut, overflow_dut);
	endtask

	assign tb_match = ( { s_ref, overflow_ref } === ( { s_ref, overflow_ref } ^ { s_dut, overflow_dut } ^ { s_ref, overflow_ref } ) );

	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				report_mismatch();
			end
			stats1.errors++;
		end
		if (s_ref !== ( s_ref ^ s_dut ^ s_ref ))
		begin 
			if (stats1.errors_s == 0) stats1.errortime_s = $time;
			stats1.errors_s = stats1.errors_s+1'b1; 
		end
		if (overflow_ref !== ( overflow_ref ^ overflow_dut ^ overflow_ref ))
		begin 
			if (stats1.errors_overflow == 0) stats1.errortime_overflow = $time;
			stats1.errors_overflow = stats1.errors_overflow+1'b1; 
		end

	end

   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

	final begin
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end

		if (stats1.errors_s) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "s", stats1.errors_s, stats1.errortime_s);
		else $display("Hint: Output '%s' has no mismatches.", "s");
		if (stats1.errors_overflow) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "overflow", stats1.errors_overflow, stats1.errortime_overflow);
		else $display("Hint: Output '%s' has no mismatches.", "overflow");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule