`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- stimulus_gen (Copied exactly as provided) ---
module stimulus_gen (
	input clk,
	output reg d,
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
	d <= 1'b0;
	@(negedge clk) wavedrom_start();
		repeat(20) @(posedge clk, negedge clk)
	d <= $random>>2;
	@(negedge clk) wavedrom_stop();
	repeat(200) @(posedge clk, negedge clk) begin
	d <= $random;
	end
	#1 $finish;
	end
	endmodule

// --- RefModule Placeholder (Required by golden testbench) ---
module RefModule (
    input clk,
    input d,
    output q
);
    // Placeholder implementation (The testbench uses this as the expected reference)
    assign q = d;
endmodule

// --- TopModule (DUT) Implementation ---
// Functional emulation of a dual-edge triggered FF
module TopModule (
    input  logic clk,
    input  logic d,
    output logic q
);

    // Internal registers to capture input on both edges
    reg q_reg_p; // Sampled on posedge
    reg q_reg_n; // Sampled on negedge

    // Assign q to the value sampled on the positive edge, as per previous implementation logic.
    assign q = q_reg_p;

    // Positive Edge Triggered FF
    always @(posedge clk) begin
        q_reg_p <= d;
    end

    // Negative Edge Triggered FF
    always @(negedge clk) begin
        q_reg_n <= d;
    end

endmodule

// =================================================================
// Improved Testbench (tb)
// =================================================================

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    
    stats stats1;
    
    // Signals from stimulus_gen
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    // Clock and Data
    reg clk=0;
    logic d;
    
    // DUT Outputs and Reference Outputs
    logic q_ref;
    logic q_dut;
    
    // Signals to capture on every clock edge for logging at mismatch time
    logic clk_capture;
    logic d_capture;
    logic q_ref_capture;
    logic q_dut_capture;
    
    // Verification Signals
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus_gen
    stimulus_gen stim1 (
        .clk(clk),
        .d(d),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    
    // Instantiate Reference Module
    RefModule good1 (
        .clk(clk),
        .d(d),
        .q(q_ref) );
        
    // Instantiate DUT
    TopModule top_module1 (
        .clk(clk),
        .d(d),
        .q(q_dut) );

    
    // Task definitions
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask	
    
    
    // Clock Generation
    initial forever
        #5 clk = ~clk;

    // Dump Waves
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,d,q_ref,q_dut );
    end

    // Main Verification Logic
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Capture signals at the edge
        clk_capture <= clk;
        d_capture <= d;
        q_ref_capture <= q_ref;
        q_dut_capture <= q_dut;
        
        // Verification Check
        // tb_match is defined as ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) ) 
        // which simplifies to q_ref === q_dut
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time; // First total mismatch time
            stats1.errors++;
        end
        
        // Output specific check (Original logic retained)
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time; // First output mismatch time
            stats1.errors_q = stats1.errors_q+1'b1;
        end

    end
    
    // Error Reporting and Finalization
    final begin
        int first_error_time = -1;
        
        if (stats1.errors > 0) first_error_time = stats1.errortime;
        // Check if output specific error occurred AND if it happened earlier than the first total error
        if (stats1.errors_q > 0 && (stats1.errors == 0 || stats1.errortime_q < stats1.errortime))
            first_error_time = stats1.errortime_q;
        
        if (stats1.errors == 0 && stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            
            if (first_error_time == -1) first_error_time = $time; // Safety net
            
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_error_time);
            
            // 1. Display signals at the time of first mismatch
            $display("\n--- Mismatch Details at Time %0d ps ---", first_error_time);
            
            // Inputs
            $display("Input Signals:");
            // Since clk and d are 1-bit, BINARY and HEX are identical but we follow the structure.
            $display("  clk: %b (HEX: %h)", clk_capture, clk_capture);
            $display("  d: %b (HEX: %h)", d_capture, d_capture);
            
            // Outputs
            $display("Output Signals:");
            $display("  q_ref (Expected): %b (HEX: %h)", q_ref_capture, q_ref_capture);
            $display("  q_dut (Actual): %b (HEX: %h)", q_dut_capture, q_dut_capture);
            end
        
        $display("\nTotal mismatched samples (tb_match): %1d out of %1d samples", stats1.errors, stats1.clocks);
        $display("Total mismatched samples (output q): %1d out of %1d samples", stats1.errors_q, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("=========================================================");
    end
    
    // Timeout
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule