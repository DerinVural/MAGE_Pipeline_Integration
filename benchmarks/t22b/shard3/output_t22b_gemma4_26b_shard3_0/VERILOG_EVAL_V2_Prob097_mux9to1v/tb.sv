`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [15:0] a,b,c,d,e,f,g,h,i,
	output logic [3:0] sel,
	output logic [511:0] wavedrom_title,
	output logic wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	
	
	initial begin
		{a,b,c,d,e,f,g,h,i,sel} <= { 16'ha, 16'hb, 16'hc, 16'hd, 16'he, 16'hf, 16'h11, 16'h12, 16'h13, 4'h0 };
		@(negedge clk) wavedrom_start();
			@(posedge clk) sel <= 4'h1;
			@(posedge clk) sel <= 4'h2;
			@(posedge clk) sel <= 4'h3;
			@(posedge clk) sel <= 4'h4;
			@(posedge clk) sel <= 4'h7;
			@(posedge clk) sel <= 4'h8;
			@(posedge clk) sel <= 4'h9;
			@(posedge clk) sel <= 4'ha;
			@(posedge clk) sel <= 4'hb;
		@(negedge clk) wavedrom_stop();
			
		repeat(200) @(negedge clk, posedge clk) begin
			{a,b,c,d,e,f,g,h,i,sel} <= {$random, $random, $random, $random, $random};
		end
		$finish;
	end
	
endmodule

module RefModule (
    input  logic [15:0] a, b, c, d, e, f, g, h, i,
    input  logic [3:0]  sel,
    output logic [15:0] out
);
    always_comb begin
        case(sel)
            4'h0: out = a;
            4'h1: out = b;
            4'h2: out = c;
            4'h3: out = d;
            4'h4: out = e;
            4'h5: out = f;
            4'h6: out = g;
            4'h7: out = h;
            4'h8: out = i;
            default: out = 16'hFFFF;
        endcase
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

	logic [15:0] a;
	logic [15:0] b;
	logic [15:0] c;
	logic [15:0] d;
	logic [15:0] e;
	logic [15:0] f;
	logic [15:0] g;
	logic [15:0] h;
	logic [15:0] i;
	logic [3:0] sel;
	logic [15:0] out_ref;
	logic [15:0] out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,e,f,g,h,i,sel,out_ref,out_dut );
	end

	wire tb_match;       // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.a,
		.b,
		.c,
		.d,
		.e,
		.f,
		.g,
		.h,
		.i,
		.sel );
	RefModule good1 (
		.a,
		.b,
		.c,
		.d,
		.e,
		.f,
		.g,
		.h,
		.i,
		.sel,
		.out(out_ref) );
		
	TopModule top_module1 (
		.a,
		.b,
		.c,
		.d,
		.e,
		.f,
		.g,
		.h,
		.i,
		.sel,
		.out(out_dut) );

	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end
	endtask	

	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

	bit first_mismatch_logged = 0;

	always @(posedge clk, negedge clk) begin
		if (!tb_match && !first_mismatch_logged) begin
			$display("FIRST MISMATCH DETECTED AT TIME %0t:", $time);
			$display("Inputs: a=%h(%b), b=%h(%b), c=%h(%b), d=%h(%b), e=%h(%b), f=%h(%b), g=%h(%b), h=%h(%b), i=%h(%b), sel=%h(%b)", 
				a, a, b, b, c, c, d, d, e, e, f, f, g, g, h, h, i, i, sel, sel);
			$display("Expected: out=%h(%b)", out_ref, out_ref);
			$display("Actual:   out=%h(%b)", out_dut, out_dut);
			first_mismatch_logged = 1;
		end
	end

	// Original error counting logic
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; 
		end
	end

	// Timeout
	initial begin
		#1000000
		$display("TIMEOUT");
		$finish();
	end

	final begin
		if (stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
			if (stats1.errors > 0) $display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors, stats1.errortime);
			else $display("Hint: Output 'out' has no mismatches.");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			$display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out, stats1.errortime_out);
		end
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule