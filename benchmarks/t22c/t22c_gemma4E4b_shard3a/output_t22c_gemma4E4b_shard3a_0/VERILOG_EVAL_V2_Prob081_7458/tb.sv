`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- DUT Definition (Included for self-containment of the testbench) ---
module TopModule (
    input logic p1a,
    input logic p1b,
    input logic p1c,
    input logic p1d,
    input logic p1e,
    input logic p1f,
    input logic p2a,
    input logic p2b,
    input logic p2c,
    input logic p2d,
    output logic p1y,
    output logic p2y
);
    // Intermediate wires for AND gates (following the instruction hint from the spec)
    logic and1_out;
    logic and2_out;
    logic and3_out;
    logic and4_out;

    // p1y: OR of (p1a & p1b & p1c) and (p1d & p1e & p1f)
    assign and1_out = p1a & p1b & p1c;
    assign and2_out = p1d & p1e & p1f;
    assign p1y = and1_out | and2_out;

    // p2y: OR of (p2a & p2b) and (p2c & p2d)
    assign and3_out = p2a & p2b;
    assign and4_out = p2c & p2d;
    assign p2y = and3_out | and4_out;
endmodule

// --- Stimulus Generator (Kept as is from golden testbench) ---
module stimulus_gen (
    input logic clk,
    output logic p1a, p1b, p1c, p1d, p1e, p1f,
    output logic p2a, p2b, p2c, p2d,
    output logic[511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input logic[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
    
    initial begin
        int count; count = 0;
        {p1a,p1b,p1c,p1d,p1e,p1f} <= 4'h0;        
        {p2a,p2b,p2c,p2d} <= 4'h0;        
        wavedrom_start();
        repeat(20) @(posedge clk) begin
            {p1a,p1b,p1c,p1d,p1e,p1f} <= {count[2:0], count[3:1]};        
            {p2a,p2b,p2c,p2d} <= count;        
            count = count + 1;
        end
        wavedrom_stop();

        repeat(400) @(posedge clk,negedge clk) begin
            {p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d} <= $random;
        end
        
        #1 $finish;
    end
    
endmodule

module tb();

    // Helper structure to hold statistics and error details
    typedef struct packed {
        int errors;
        int errortime;
        int errors_p1y;
        int errortime_p1y;
        int errors_p2y;
        int errortime_p2y;
        int clocks;
    } stats;
    
    stats stats1;
    
    // Signal Declarations
    logic[511:0] wavedrom_title;
    logic wavedrom_enable;
    int wavedrom_hide_after_time;
    
    // Clock Generation
    logic clk = 0;
    initial forever
        #5 clk = ~clk;

    // DUT/Reference Signal Declarations (1-bit signals as per instantiation)
    logic p1a, p1b, p1c, p1d, p1e, p1f;
    logic p2a, p2b, p2c, p2d;
    logic p1y_ref, p1y_dut;
    logic p2y_ref, p2y_dut;

    // Testbench Utilities
    
    // Task to display mismatch details (As required by prompt)
    task report_mismatch;
        input string signal_name;
        input logic dut_val;
        input logic ref_val;
        input logic[9:0] inputs_val;
        
        begin
            $display("
==================================================================");
            $display("FIRST MISMATCH DETECTED at Time = %0t ps for Signal %s", $time, signal_name);
            $display("------------------------------------------------------------------");
            // Display Inputs (10 bits)
            $display("Input Signals:  %b (%h)", inputs_val, inputs_val);
            // Display Outputs (1 bit, showing both formats)
            $display("Output Signals: DUT = %b (%h) | Expected = %b (%h)", dut_val, dut_val, ref_val, ref_val);
            $display("==================================================================");
        endtask
    endtask

    // --- Testbench Instantiations ---
    
    // 1. Stimulus Generator
    stimulus_gen stim1 (
        .clk, clk,
        .p1a, p1a,
        .p1b, p1b,
        .p1c, p1c,
        .p1d, p1d,
        .p1e, p1e,
        .p1f, p1f,
        .p2a, p2a,
        .p2b, p2b,
        .p2c, p2c,
        .p2d, p2d,
        .wavedrom_title, wavedrom_title,
        .wavedrom_enable, wavedrom_enable
    );
    
    // 2. Reference Module (Golden) - Assumed to exist and match logic
    RefModule good1 (
        .p1a, p1a,
        .p1b, p1b,
        .p1c, p1c,
        .p1d, p1d,
        .p1e, p1e,
        .p1f, p1f,
        .p2a, p2a,
        .p2b, p2b,
        .p2c, p2c,
        .p2d, p2d,
        .p1y(p1y_ref),
        .p2y(p2y_ref) 
    );
    
    // 3. DUT Instantiation
    TopModule top_module1 (
        .p1a, p1a,
        .p1b, p1b,
        .p1c, p1c,
        .p1d, p1d,
        .p1e, p1e,
        .p1f, p1f,
        .p2a, p2a,
        .p2b, p2b,
        .p2c, p2c,
        .p2d, p2d,
        .p1y(p1y_dut),
        .p2y(p2y_dut) 
    );
    
    // Global state tracking for error reporting
    
    // Verification Logic
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Verification: XOR comparison logic
    assign tb_match = ( { p1y_ref, p2y_ref } === ( { p1y_ref, p2y_ref } ^ { p1y_dut, p2y_dut } ^ { p1y_ref, p2y_ref } ) );
    
    // Initial signal logging
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,p1a,p1b,p1c,p1d,p1e,p1f,p2a,p2b,p2c,p2d,p1y_ref,p1y_dut,p2y_ref,p2y_dut );
        $display("--- Starting Simulation ---");
    end

    // Clocked verification and error tracking
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Combine all inputs into one vector for display purposes
        logic [9:0] all_inputs = {p1a,p1b,p1c,p1d,p1e,p1f,p2a,p2b,p2c,p2d};
        
        // Check overall mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Report overall mismatch state
                report_mismatch("Overall", p1y_dut, p2y_dut, all_inputs);
            end
            stats1.errors++;
        end
        
        // Check p1y mismatch
        if (p1y_ref !== ( p1y_ref ^ p1y_dut ^ p1y_ref ))
        begin 
            if (stats1.errors_p1y == 0) begin
                stats1.errortime_p1y = $time;
                // Report p1y mismatch state
                report_mismatch("p1y", p1y_dut, p1y_ref, all_inputs);
            end
            stats1.errors_p1y = stats1.errors_p1y + 1'b1;
        end
        
        // Check p2y mismatch
        if (p2y_ref !== ( p2y_ref ^ p2y_dut ^ p2y_ref ))
        begin 
            if (stats1.errors_p2y == 0) begin
                stats1.errortime_p2y = $time;
                // Report p2y mismatch state
                report_mismatch("p2y", p2y_dut, p2y_ref, all_inputs);
            end
            stats1.errors_p2y = stats1.errors_p2y + 1'b1;
        end
    end
    
    // Timeout mechanism
    initial begin
        #1000000
        $display("
!!! TIMEOUT REACHED !!!");
        $finish();
    end
    
    // Final Reporting Block
    initial begin
        // Wait for a stable state after the last clock edge
        @(negedge clk);
        #10;
        
        $display("
==================================================================");
        $display("SIMULATION SUMMARY");
        $display("==================================================================");
        
        // Check p1y
        if (stats1.errors_p1y > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d (p1y)", stats1.errors_p1y, stats1.errortime_p1y);
        end else begin
            $display("Output 'p1y' passed all checks.");
        end
        
        // Check p2y
        if (stats1.errors_p2y > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d (p2y)", stats1.errors_p2y, stats1.errortime_p2y);
        end else begin
            $display("Output 'p2y' passed all checks.");
        end
        
        // Final overall check (Prioritizing the first overall error if any)
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
        
        $display("Total mismatched samples: %0d out of %0d samples.", stats1.errors, stats1.clocks);
        $finish();
    end

endmodule