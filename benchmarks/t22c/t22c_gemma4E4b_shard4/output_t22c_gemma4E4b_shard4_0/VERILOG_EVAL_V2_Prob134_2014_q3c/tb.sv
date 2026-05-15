`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Module to generate stimulus (Kept as per golden testbench)
module stimulus_gen (
	input clk,
	output logic x,
	output logic [2:0] y
);
	initial begin
		repeat(200) @(posedge clk, negedge clk) begin
		y <= $random;
		x <= $random;
		end
		#1 $finish;
	end
endmodule

// Reference Module (Placeholder, kept as per golden testbench structure)
module RefModule (
    input logic clk,
    input logic x,
    input logic [2:0] y,
    output logic Y0,
    output logic z
);
    // Minimal placeholder implementation to allow simulation to proceed
    assign Y0 = y[0];
    assign z = (y[2] & y[1]);
endmodule

// The DUT Module (TopModule, which we are testing) - Defined here for compilation context
module TopModule (
    input  logic clk,
    input  logic x,
    input  logic [2:0] y,
    output logic Y0,
    output logic z
);
    // Placeholder implementation matching the required interface
    // Actual logic should be implemented in the module under test.
    assign Y0 = y[0]; 
    assign z = 1'b0;
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_Y0;
        int errortime_Y0;
        int errors_z;
        int errortime_z;
        int clocks;
        // Fields to capture first mismatch details
        int first_mismatch_time;
        logic first_mismatch_x;
        logic [2:0] first_mismatch_y;
        logic first_mismatch_Y0_dut;
        logic first_mismatch_z_dut;
        logic first_mismatch_Y0_ref;
        logic first_mismatch_z_ref;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic x;
    logic [2:0] y;
    logic Y0_ref;
    logic Y0_dut;
    logic z_ref;
    logic z_dut;

    // State tracking for first mismatch event
    reg mismatch_captured = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,x,y,Y0_ref,Y0_dut,z_ref,z_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator
    stimulus_gen stim1 (
        .clk(clk),
        .x(x),
        .y(y) // Using positional mapping based on golden testbench structure
    );

    // Instantiate Reference Module
    RefModule good1 (
        .clk(clk),
        .x(x),
        .y(y),
        .Y0(Y0_ref),
        .z(z_ref) 
    );
        
    // Instantiate DUT
    TopModule top_module1 (
        .clk(clk),
        .x(x),
        .y(y),
        .Y0(Y0_dut),
        .z(z_dut) 
    );

    // Verification: Simple equality check
    assign tb_match = ( { Y0_ref, z_ref } === { Y0_dut, z_dut } );

    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Capture first mismatch details
            if (stats1.errors == 1) begin
                stats1.first_mismatch_time = $time;
                stats1.first_mismatch_x = x;
                stats1.first_mismatch_y = y;
                stats1.first_mismatch_Y0_dut = Y0_dut;
                stats1.first_mismatch_z_dut = z_dut;
                stats1.first_mismatch_Y0_ref = Y0_ref;
                stats1.first_mismatch_z_ref = z_ref;
                mismatch_captured = 1;
            end
        end
        
        // Check Y0 mismatch
        if (Y0_ref !== Y0_dut)
        begin 
            if (stats1.errors_Y0 == 0) stats1.errortime_Y0 = $time;
            stats1.errors_Y0 = stats1.errors_Y0+1'b1;
        end
        
        // Check z mismatch
        if (z_ref !== z_dut)
        begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z+1'b1;
        end

    end

    // Final Reporting Block
    final begin
        // 1. Required Success/Failure Display
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
            $display("
--- Mismatch Details at Time %0d ps ---", stats1.first_mismatch_time);
            
            // 2. Detailed Display of First Mismatch (Required format)
            // Display Inputs
            $display("Input Signals:");
            $display("  clk: %b", clk);
            $display("  x: %b", stats1.first_mismatch_x);
            $display("  y: %h (%b)", stats1.first_mismatch_y, stats1.first_mismatch_y); // Width <= 64, so binary is fine
            
            // Display Outputs
            $display("Output Signals:");
            $display("  DUT Y0: %h (%b)", stats1.first_mismatch_Y0_dut, stats1.first_mismatch_Y0_dut);
            $display("  DUT z:  %h (%b)", stats1.first_mismatch_z_dut, stats1.first_mismatch_z_dut);
            $display("  REF Y0: %h (%b)", stats1.first_mismatch_Y0_ref, stats1.first_mismatch_Y0_ref);
            $display("  REF z:  %h (%b)", stats1.first_mismatch_z_ref, stats1.first_mismatch_z_ref);
            $display("----------------------------------------");
        end
        
        // Original Hint Reporting (Kept for functional similarity)
        if (stats1.errors_Y0) $display("Hint: Output 'Y0' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_Y0, stats1.errortime_Y0);
        else $display("Hint: Output 'Y0' has no mismatches.");
        if (stats1.errors_z) $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output 'z' has no mismatches.");
        
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule