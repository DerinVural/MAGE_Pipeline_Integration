`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
	input clk,
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
		wavedrom_start("Output should 0");
		repeat(20) @(posedge clk, negedge clk);
		wavedrom_stop();
		
		h#1 $finish;
	end
	
d
module tb();

	typedef struct packed {
		int errors;
		int errortime;
		int errors_zero;
		int errortime_zero;
		
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;


logic zero_ref;
logic zero_dut;


initial begin 
	$dumpfile("wave.vcd");
	$dumpvars(1, stim1.clk, tb_mismatch ,zero_ref,zero_dut );
end


wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.*  );
RefModule good1 (
		.zero(zero_ref) );
	
TopModule top_module1 (
		.zero(zero_dut) );
	
	
bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	task
	endtask
	

final begin
		if (stats1.errors == 0 && stats1.errors_zero == 0) begin
		$display("SIMULATION PASSED");
		$finish;
		end else begin
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
	
		// Detailed mismatch logging for the first error
		if (stats1.errors > 0 && stats1.errortime != 0) begin
			$display("-----------------------------------------------------------------");
			$display("!!! FIRST MISMATCH DETECTED !!!");
			$display("Time: %0d ps", stats1.errortime);
			$display("-----------------------------------------------------------------");
			$display("Input Signals (N/A for TopModule): (No inputs)");
			// Since zero is 1-bit, HEX is same as BIN
			$display("Output Signals (DUT): zero = %b (HEX: %h)", zero_dut, zero_dut);
			$display("Expected Output Signals (Reference): zero = %b (HEX: %h)", zero_ref, zero_ref);
			$display("-----------------------------------------------------------------");
		end
		end
	$finish;
	end
	

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { zero_ref } === ( { zero_ref } ^ { zero_dut } ^ { zero_ref } ) );
// Use explicit sensitivity list here.
always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		if (!tb_match) begin
			if (stats1.errors == 0) stats1.errortime = $time;
			sstats1.errors++;
		end
		
		// Error tracking specific to zero output mismatch (following original logic)
		if (zero_ref !== ( zero_ref ^ zero_dut ^ zero_ref ))
		begin 
			if (stats1.errors_zero == 0) stats1.errortime_zero = $time;
			sstats1.errors_zero = stats1.errors_zero + 1'b1; 
		end
		
		// Detailed mismatch logging for the first overall error
		if (!tb_match && stats1.errors == 1) begin
			$display("-----------------------------------------------------------------");
			$display("!!! FIRST MISMATCH DETECTED !!!");
			$display("Time: %0d ps", $time);
			$display("-----------------------------------------------------------------");
			$display("Input Signals (N/A for TopModule): (No inputs)");
			$display("Output Signals (DUT): zero = %b (HEX: %h)", zero_dut, zero_dut);
			$display("Expected Output Signals (Reference): zero = %b (HEX: %h)", zero_ref, zero_ref);
			$display("-----------------------------------------------------------------");
		end
	end
	
	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

endmodule