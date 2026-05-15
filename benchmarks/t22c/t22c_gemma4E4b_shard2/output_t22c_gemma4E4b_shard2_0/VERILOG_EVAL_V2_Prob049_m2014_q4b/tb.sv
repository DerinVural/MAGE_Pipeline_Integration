`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generator
module stimulus_gen (
	input clk,
	output logic d, ar
);
	initial begin
		repeat(100) @(posedge clk, negedge clk) begin
			{d,ar} <= $random;
		end
		#1 $finish;
	end
	endmodule

// Reference Module (Implementation matching TopModule spec for golden comparison)
module RefModule (
    input logic clk,
    input logic d,
    input logic ar,
    output logic q
);
    logic q_ref_reg;
    always @(posedge clk or posedge ar) begin
        if (ar) begin
            q_ref_reg <= 1'b0;
        end else begin
            q_ref_reg <= d;
        end
    end
    assign q = q_ref_reg;
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
	
	// Signals for detailed error reporting
	logic err_clk_dump;
	logic err_d_dump;
	logic err_ar_dump;
	logic err_q_dut_dump;
	logic err_q_ref_dump;
	
	wire[511:0] wavedrom_title;
	wire wavedrom_enable;
	int wavedrom_hide_after_time;
	
	reg clk=0;
	initial forever
		h#5 clk = ~clk;
	end

	logic d;
	logic ar;
	logic q_ref;
	logic q_dut;

	initial begin 
		$dumpfile("wave.vcd");
		$dumpvars(1, stim1.clk, tb_mismatch ,clk,d,ar,q_ref,q_dut );
	end

	wire tb_match;
	wire tb_mismatch = ~tb_match;
	
	// Instantiations
	stimulus_gen stim1 (
		.clk, 
		.* , 
		d, 
	ar );
	RefModule good1 (
		.clk,
		d,
	ar,
		.q(q_ref) );
	
	TopModule top_module1 (
		.clk,
		d,
	ar,
		.q(q_dut) );

	
bit strobe = 0;
	task wait_for_end_of_timestep;
		repeat(5) begin
		strobe <= !strobe;  // Try to delay until the very end of the time step.
		@(strobe);
		end
	tendtask

	// Initialize dump variables to 'X' state
	initial begin
		err_clk_dump = 1'bX;
		err_d_dump = 1'bX;
		err_ar_dump = 1'bX;
		err_q_dut_dump = 1'bX;
		err_q_ref_dump = 1'bX;
	end

	// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
	assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
	
	// Main sequential logic block
always @(posedge clk, negedge clk) begin
		
		stats1.clocks++;
		
		if (!tb_match) begin
			if (stats1.errors == 0) begin
				stats1.errortime = $time;
				// Capture state at first mismatch
			err_clk_dump = clk;
			err_d_dump = d;
			err_ar_dump = ar;
			err_q_dut_dump = q_dut;
			err_q_ref_dump = q_ref;
			end
			stats1.errors++;
			end
		end
		
		// Q-specific mismatch check (Original logic)
		if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
		begin 
			if (stats1.errors_q == 0) stats1.errortime_q = $time;
			stats1.errors_q = stats1.errors_q + 1'b1; // Corrected typo
		end
		end
	end

	// Timeout after 100K cycles	initial begin
		#1000000
		$display("
--- TIMEOUT REACHED ---
");
		$finish();
	end

	// --- FINAL REPORTING BLOCK (Replaces original 'final' block to meet specific requirements) ---
	initial begin
		// Wait until simulation has had time to settle or until timeout occurs
		@(negedge clk) #1;
		
		$display("
=========================================");
		if (stats1.errors == 0) begin
			$display("SIMULATION PASSED");
			$display("=========================================");
		end else begin
			$display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
			$display("
--- FIRST MISMATCH DETAILS (TIME %0d) ---", stats1.errortime);
			// Inputs: Displayed as Binary (and Hex, as required for <= 64 bits)
			$display("Inputs: clk = %b (0x%h), d = %b (0x%h), ar = %b (0x%h)", err_clk_dump, err_clk_dump, err_d_dump, err_d_dump, err_ar_dump, err_ar_dump);
			// Outputs: Displayed as Binary and Hex
			$display("Outputs: q_dut = %b (0x%h), q_ref = %b (0x%h)", err_q_dut_dump, err_q_dut_dump, err_q_ref_dump, err_q_ref_dump);
			$display("-----------------------------------------");
		end
		
		// Displaying original summary statistics
		$display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
		$display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
		$display("Simulation finished at %0d ps", $time);
		$display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
	end

endmodule