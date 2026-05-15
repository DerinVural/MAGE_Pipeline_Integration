`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
	output logic sel,
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
		{a, b, sel} <= '0;
		@(negedge clk) wavedrom_start("");
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b0};
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
			@(posedge clk, negedge clk) {a,b,sel} <= {8'haa, 8'hbb, 1'b1};
			
			@(posedge clk, negedge clk) {a, b} <= {8'hff, 8'h00}; sel <= 1'b0;
			@(posedge clk, negedge clk) sel <= 1'b0;
			@(posedge clk, negedge clk) sel <= 1'b1;
			@(posedge clk, negedge clk) sel <= 1'b0;
			@(posedge clk, negedge clk) sel <= 1'b1;
			@(posedge clk, negedge clk) sel <= 1'b1;
		wavedrom_stop();
		
		repeat(100) @(posedge clk, negedge clk)
			{a,b,sel} <= $urandom;
		$finish;
	end
	
endmodule

module RefModule (
    input  logic       sel,
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] out
);
    assign out = sel ? b : a;
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

	logic sel;
	logic [7:0] a;
	logic [7:0] b;
	logic [7:0] out_ref;
	logic [7:0] out_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,sel,a,b,out_ref,out_dut );
	end


	wire tb_match;        // Verification
	wire tb_mismatch = ~tb_match;
	
	stimulus_gen stim1 (
		.clk,
		.* ,
		.sel,
		.a,
		.b );
	RefModule good1 (
		.sel,
		.a,
		.b,
		.out(out_ref) );
		
	TopModule top_module1 (
		.sel,
		.a,
		.b,
		.out(out_dut) );


	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
			strobe <= !strobe;  // Try to delay until the very end of the time step.
			@(strobe);
		end;
	endtask	

	bit first_mismatch_reported = 0;

	assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

	always @(posedge clk, negedge clk) begin

		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			stats1.errors++;
			if (!first_mismatch_reported) begin
				$display("Mismatch detected at time %0t:", $time);
				$display("sel=%b, a=%h (%b), b=%h (%b), out_ref=%h (%b), out_dut=%h (%b)", 
					sel, a, a, b, b, out_ref, out_ref, out_dut, out_dut);
				first_mismatch_reported = 1;
			end
		end;
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) stats1.errortime_out = $time;
			stats1.errors_out = stats1.errors_out+1'b1; 
		end;

	end;

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

	final begin
		if (stats1.errors_out == 0) begin
			$display("SIMULATION PASSED");
			$display("Hint: Output '%s' has no mismatches.", "out");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			$display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
		end;

		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end;

endmodule