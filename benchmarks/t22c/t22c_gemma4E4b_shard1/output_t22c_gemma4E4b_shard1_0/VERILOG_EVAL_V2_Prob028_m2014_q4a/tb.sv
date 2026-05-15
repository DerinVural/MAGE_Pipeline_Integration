`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


module stimulus_gen (
	input clk,
	output logic d, ena
);

	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{d,ena} <= $random;
		end
		
		#1 $finish;
	end
	endmodule

// Dummy module to satisfy instantiation requirement from golden_testbench
module RefModule (
	input d,
	input ena,
	output q
);
    // Following the golden testbench logic: simple pass-through reference model
    assign q = d;
endmodule

// DUT implementation based on input_spec (D Latch using always block)
module TopModule (
    input logic d,
    input logic ena,
    output logic q
);
    logic q_reg;

    // D Latch implementation using always @(*) block as per input spec
    always @(*)
    begin
        if (ena) begin
            // Transparent mode: q follows d
            q_reg = d;
        end else begin
            // Hold mode: q retains its current value (latch behavior)
            q_reg = q_reg; // Retain previous value
        end
    end
    
    // Drive the output port
    assign q = q_reg;
endmodule

module tb();
	typedef struct packed {
		int errors;
		int errortime;
		int errors_q;
		int errortime_q;
		int clocks;
	} stats;
	
	stats stats1;
	
	
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
	
	reg clk=0;
initial forever
		#5 clk = ~clk;

logic d;
logic ena;
logic q_ref;
logic q_dut;
	
logic [1:0] first_error_d, first_error_ena, first_error_q_ref, first_error_q_dut;
	
initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,d,ena,q_ref,q_dut );
	end

wire tb_match;
wire tb_mismatch = ~tb_match;
	
stimulus_gen stim1 (
		.clk,
		.* ,
		d, ena );
RefModule good1 (
		d, ena,
		.q(q_ref) );
	
TopModule top_module1 (
		d, ena,
		.q(q_dut) );
	

bit strobe = 0;
task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask
	
	
final begin
		int total_errors = stats1.errors + stats1.errors_q;
		if (total_errors == 0) begin
			s$display("SIMULATION PASSED");
			return;
		end
		
		// Determine the absolute first error time
		if (stats1.errortime > 0 && stats1.errortime_q > 0) begin
			first_error_time = (stats1.errortime < stats1.errortime_q) ? stats1.errortime : stats1.errortime_q;
		end else if (stats1.errortime > 0) begin
			first_error_time = stats1.errortime;
		end else if (stats1.errortime_q > 0) begin
			first_error_time = stats1.errortime_q;
		end
		
		$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_errors, first_error_time);
		
		// Display details of the first mismatch
		$display("\n--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", first_error_time);
		// Inputs (D/ENA)
		// Since signals are 1-bit, D=D_bin (0xD), ENA=ENA_bin (0xENA)
		$display("Inputs (D/ENA): D=%b (0x%h), ENA=%b (0x%h)", first_error_d, first_error_d, first_error_ena, first_error_ena);
		// Outputs (Reference vs DUT)
		$display("Outputs (Q_REF/Q_DUT): Q_REF=%b (0x%h), Q_DUT=%b (0x%h)", first_error_q_ref, first_error_q_ref, first_error_q_dut, first_error_q_dut);
		$display("---------------------------------------");
		
		$display("Total mismatched samples is %1d out of %1d samples\n", total_errors, stats1.clocks);
	end
	
// Verification: Comparison based on single bits
assign tb_match = ( q_ref === q_dut );
	
// Clocked verification logic
always @(posedge clk, negedge clk) begin
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
			stats1.errortime = $time;
			first_error_time = $time;
			first_error_d = d;
			first_error_ena = ena;
			first_error_q_ref = q_ref;
			first_error_q_dut = q_dut;
		end
		stats1.errors++;
		end
		
		// Original Q mismatch logic maintained
		if (q_ref !== q_dut) 
		begin 
			if (stats1.errors_q == 0) begin
			stats1.errortime_q = $time;
			first_error_time = $time;
			first_error_d = d;
			first_error_ena = ena;
			first_error_q_ref = q_ref;
			first_error_q_dut = q_dut;
		end
		stats1.errors_q = stats1.errors_q+1'b1; 
		end
	end
	
// add timeout after 100K cycles
initial begin
	#1000000
	// The final block handles the PASS/FAIL based on accumulated errors
	end
	$finish();
end

endmodule