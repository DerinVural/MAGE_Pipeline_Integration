`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output reg in,
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
		wavedrom_start("Output should follow input");
		repeat(20) @(posedge clk, negedge clk)
			in <= $random;
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk) begin
			in <= $random;
		end
		
		#1 $finish;
	end
	
endmodule

module tb();
	
typeof stats;
	struct packed {
		int errors;
		int errortime;
		int errors_out;
		int errortime_out;

		int clocks;
	};
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
initial forever
		h#5 clk = ~clk;


logic in;
logic out_ref;
logic out_dut;


logic[511:0] first_mismatch_title; // To capture signals at first mismatch
logic first_mismatch_in;
logic first_mismatch_out_ref;
logic first_mismatch_out_dut;


initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
	end


wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk, 
		.* , 
		.in );
		
RefModule good1 (
		.in, 
		out(out_ref) );
		
TopModule top_module1 (
		.in, 
		out(out_dut) );


bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	

	initial begin
		stats1 = '{errors: 0, errortime: 0, errors_out: 0, errortime_out: 0, clocks: 0};
		$display("Starting simulation...");
	end
	

final begin
		if (stats1.errors_out > 0) begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
			$display("--- FIRST OUTPUT MISMATCH DETAILS ---");
			$display("Time: %0d ps", stats1.errortime_out);
			$display("Input Signals:");
			$display("  in: %b", first_mismatch_in);
			$display("Output Signals:");
			$display("  DUT Output (out_dut): %b (HEX: %h)", first_mismatch_out_dut, first_mismatch_out_dut);
			$display("Expected Output Signals:");
			$display("  Reference Output (out_ref): %b (HEX: %h)", first_mismatch_out_ref, first_mismatch_out_ref);
			$display("Expected Output (w.r.t. reference): %b", first_mismatch_out_ref ^ first_mismatch_out_dut ^ first_mismatch_out_ref);
			$display("Wavedrom Title (Input to DUT context):");
			$display("  HEX: %h", first_mismatch_title);
			$display("  BIN (Truncated for display, max 64 bits): %b", first_mismatch_title[63:0]);
		end
		else begin
			$display("SIMULATION PASSED");
		end
		
		$display("\n========================================");
		$display("Total mismatched samples is %1d out of %1d samples", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("========================================");
	end
	
// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

// Logic to capture first error details and track stats
always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture signals at first mismatch
				first_mismatch_in = in;
				first_mismatch_out_ref = out_ref;
				first_mismatch_out_dut = out_dut;
				first_mismatch_title = wavedrom_title;
			end
			s
			stats1.errors++;
		end
		
		if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
		begin 
			if (stats1.errors_out == 0) begin
				s
				errortime_out = $time;
				// Capture signals at first output mismatch
				first_mismatch_in = in;
				first_mismatch_out_ref = out_ref;
				first_mismatch_out_dut = out_dut;
				first_mismatch_title = wavedrom_title;
			end
			s
			s
			s
			s
			s
			stats1.errors_out = stats1.errors_out+1'b1; 
		end
		end


   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED");
     $finish();
   end

endmodule
