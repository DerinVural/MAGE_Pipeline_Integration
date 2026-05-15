`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic [1023:0] in,
	output logic [7:0] sel
);

	always @(posedge clk, negedge clk) begin
		for (int i=0;i<32; i++)
			in[i*32+:32] <= $random;
		sel <= $random;
	end
	
	initial begin
		repeat(1000) @(negedge clk);
		$finish;
	end
	
	
endmodule

module RefModule (
	input  logic [1023:0] in,
	input  logic [7:0]    sel,
	output logic [3:0]    out
);
	assign out = in[sel*4 +: 4];
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

	logic [1023:0] in;
	logic [7:0] sel;
	logic [3:0] out_ref;
	logic [3:0] out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,sel,out_ref,out_dut );
	end


	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk(clk),
		.* ,
		.in(in),
		.sel(sel) 
	);
	RefModule good1 (
		.in(in),
		.sel(sel),
		.out(out_ref) );
		
	TopModule top_module1 (
		.in(in),
		.sel(sel),
		.out(out_dut) );


	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	
	
	
	final begin
		if (stats1.errors_out) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		else $display("Hint: Output '%s' has no mismatches.", "out");

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
		
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
		end
	end
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
	// Use explicit sensitivity list here.
	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				$display("FIRST MISMATCH DETECTED at time %0t:", $time);
				$display("  in: %h
				  sel: %h (%b)
				  out_dut: %h (%b)
				  out_ref: %h (%b)", in, sel, sel, out_dut, out_dut, out_ref, out_ref);
			end
			stats1.errors++;
		end
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; 
		end

	end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

endmodule