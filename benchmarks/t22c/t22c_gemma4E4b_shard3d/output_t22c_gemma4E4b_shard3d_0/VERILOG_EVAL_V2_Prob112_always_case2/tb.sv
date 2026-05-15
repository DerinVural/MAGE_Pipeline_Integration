`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// The stimulus_gen module is kept exactly as provided by the golden testbench
module stimulus_gen (
	input clk,
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
		@(negedge clk) wavedrom_start("Priority encoder");
		@(posedge clk) in <= 4'h1;
		repeat(4) @(posedge clk) in <= in << 1;
		in <= 0;
		repeat(16) @(posedge clk) in <= in + 1;
		@(negedge clk) wavedrom_stop();

		repeat(50) @(posedge clk, negedge clk) begin
		in <= $urandom;
		end
		$finish;
	end
	endmodule

// Dummy RefModule required by the golden testbench
module RefModule(
    input logic [3:0] in,
    output logic [1:0] pos
);
    // For the reference model, we must implement the priority encoder logic based on spec
    always @* begin
        if (in[3])
            pos = 2'b11; // Index 3
        else if (in[2])
            pos = 2'b10; // Index 2
        else if (in[1])
            pos = 2'b01; // Index 1
        else if (in[0])
            pos = 2'b00; // Index 0
        else
            pos = 2'b00; // Zero input case
    end
endmodule

// DUT Implementation (4-bit Priority Encoder)
module TopModule(
    input  logic [3:0] in,
    output logic [1:0] pos
);
    // Priority Encoder Logic: Index 3 is highest priority
    always @* begin
        // Default assignment: If no input is high, output zero as per requirement.
        pos = 2'b00;

        // Priority check: Check from MSB (highest priority) down to LSB (lowest priority)
        if (in[3]) begin
            pos = 2'b11; // Corresponds to index 3
        end else if (in[2]) begin
            pos = 2'b10; // Corresponds to index 2
        end else if (in[1]) begin
            pos = 2'b01; // Corresponds to index 1
        end else if (in[0]) begin
            pos = 2'b00; // Corresponds to index 0
        end
    end
endmodule

module tb();
	
	typedef struct packed {
		int errors;
		int errortime;
		int errors_pos;
		int errortime_pos;
		int clocks;
	}
	stats;
	
	stats stats1;
	
	// Signals from stimulus_gen
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	
	// Clock generation
	reg clk=0;
	initial forever
		h#5 clk = ~clk;

	// Signals for DUT and Reference
	logic [3:0] in;
	logic [1:0] pos_ref;
	logic [1:0] pos_dut;

	// Variables to capture state at first mismatch
	logic [3:0] first_mismatch_in;
	logic [1:0] first_mismatch_pos_dut;
	logic [1:0] first_mismatch_pos_ref;
	integer first_mismatch_time = -1;
	
	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,in,pos_ref,pos_dut );
	end

	// Instantiate stimulus generator
	stimulus_gen stim1 (
		.clk, clk,
		in, in,
		.wavedrom_title, wavedrom_title,
		.wavedrom_enable, wavedrom_enable
	);
	
	// Instantiate Reference Model
	RefModule good1 (
		in, in,
		.pos(pos_ref) );
	
	// Instantiate DUT
	TopModule top_module1 (
		in, in,
		.pos(pos_dut) );
	
	
	bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		endtask	
	
	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { pos_ref } === ( { pos_ref } ^ { pos_dut } ^ { pos_ref } ) );
	
	// Main monitoring block
	always @(posedge clk, negedge clk) begin
		stats1.clocks++;
	
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture state at the very first mismatch
				first_mismatch_time = $time;
				first_mismatch_in = in;
				first_mismatch_pos_dut = pos_dut;
				first_mismatch_pos_ref = pos_ref;
				$display("\n=======================================================");
				$display("*** FIRST MISMATCH DETECTED AT TIME %0d ps ***", $time);
				// Display input signals (in) in HEX and BIN
				$display("Input Signals (in): Hex=%h, Binary=%b", first_mismatch_in, first_mismatch_in);
				// Display DUT output (pos_dut) in HEX and BIN
				$display("DUT Output (pos_dut): Hex=%h, Binary=%b", first_mismatch_pos_dut, first_mismatch_pos_dut);
				// Display Expected output (pos_ref) in HEX and BIN
				$display("Expected Output (pos_ref): Hex=%h, Binary=%b", first_mismatch_pos_ref, first_mismatch_pos_ref);
				$display("=======================================================\n");
				
			stats1.errors++;
				
			// Original logic for pos_ref mismatch count (kept for compatibility)
			if (pos_ref !== ( pos_ref ^ pos_dut ^ pos_ref ))
			begin 
				if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
				stats1.errors_pos = stats1.errors_pos+1'b1; 
			end
			end
		end
	
		// Original logic for pos_ref specific mismatch count (Ensuring consistency and fixing typos)
		if (pos_ref !== ( pos_ref ^ pos_dut ^ pos_ref ))
		begin 
			if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
			stats1.errors_pos = stats1.errors_pos+1'b1; 
		end
	end

	// add timeout after 100K cycles
	initial begin
		h#1000000
		$display("TIMEOUT");
		$finish();
	end

	// Final reporting block (Updated to meet new requirements)
	final begin
		if (stats1.errors == 0) begin
			$display("\n**************************************");
			$display("SIMULATION PASSED");
			$display("**************************************");
		end else begin
			$display("\n**************************************");
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("**************************************");
		end
		
		// Retaining original summary for comprehensive debugging
		$display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule