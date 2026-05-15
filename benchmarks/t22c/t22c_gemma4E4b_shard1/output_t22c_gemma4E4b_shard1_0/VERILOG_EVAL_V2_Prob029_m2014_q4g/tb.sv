`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Dummy module for the reference model, derived from the circuit logic for comparison.
module RefModule (
    input logic in1,
    input logic in2,
    input logic in3,
    output logic out
);
    // Logic: (in1 XNOR in2) XOR in3
    // XNOR(a, b) = (a & b) | (~a & ~b)
    logic xnor_intermediate;
    assign xnor_intermediate = (in1 & in2) | (~in1 & ~in2);
    assign out = xnor_intermediate ^ in3;
endmodule

// Stimulus Generator (Maintains original functionality)
module stimulus_gen (
    input clk,
    output logic in1, in2, in3
);
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            {in1, in2, in3} <= $random;
        end
        
        #1 $finish;
    end
endmodule

module tb();
    
    typedef struct packed {
        int errors;          // For tb_mismatch
        int errortime;      // First error time for tb_mismatch
        int errors_out;     // For specific check (out_ref != expected)
        int errortime_out;  // First error time for specific check
        int clocks;         // Total clocks simulated
    } stats;
    
    stats stats1;
    
    // Signal dumping setup
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    // Signals
    logic in1;
    logic in2;
    logic in3;
    logic out_ref;
    logic out_dut;

    // Verification signals
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // State capture registers for first mismatch details
    reg r_in1, r_in2, r_in3;
    reg r_out_ref, r_out_dut;
    reg r_expected_out;
    reg first_mismatch_logged = 0;
    
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen::stim1, tb);
    end

    // Instantiate stimulus generator
    stimulus_gen stim1 (
        .clk(clk),
        .in1(in1),
        .in2(in2),
        .in3(in3)
    );
    
    // Reference Model
    RefModule good1 (
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .out(out_ref)
    );
    
    // Device Under Test (DUT)
    TopModule top_module1 (
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .out(out_dut)
    );

    // Utility Task (Kept for structural similarity, though unused in error checking logic)
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask
    
    // Task to display signals in required format
    task display_signals(input string label, input logic i1, input logic i2, input logic i3, input logic ref_out, input logic dut_out, input logic expected_out);
    begin
        $display("
========================================================================");
        $display("*** %s: FIRST MISMATCH DETECTED ***", label);
        $display("Time: %0t ps", $time);
        $display("------------------------------------------------------------------------");
        // Inputs display: width <= 64, so show binary and hex
        $display("Inputs: in1 = %b (0x%h), in2 = %b (0x%h), in3 = %b (0x%h)", i1, i1, i2, i2, i3, i3);
        // Outputs display
        $display("Outputs: DUT_out = %b (0x%h), Ref_out = %b (0x%h)", dut_out, dut_out, ref_out, ref_out);
        $display("Expected: Expected_out = %b (0x%h)", expected_out, expected_out);
        $display("========================================================================");
    endtask
    
    // Initial setup for timing/state tracking
    initial begin
        stats1.clocks = 0;
        $display("--- Simulation Starting ---");
    end
    
    // Main Verification Loop
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // 1. Capture current state
        r_in1 <= in1;
        r_in2 <= in2;
        r_in3 <= in3;
        r_out_ref <= out_ref;
        r_out_dut <= out_dut;
        
        // Calculate expected output based on specification: (in1 XNOR in2) XOR in3
        r_expected_out = ((r_in1 & r_in2) | (~r_in1 & ~r_in2)) ^ r_in3;
        
        // 2. Check tb_match (Reference vs DUT behavior)
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Log first mismatch for tb_match
            if (stats1.errors == 1 && !first_mismatch_logged) begin
                display_signals("TB Mismatch", r_in1, r_in2, r_in3, r_out_ref, r_out_dut, r_expected_out);
                first_mismatch_logged = 1;
            end
        end
        
        // 3. Check specific error count (original logic: out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) 
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1'b1;
            
            // Log first mismatch for errors_out
            if (stats1.errors_out == 1 && !first_mismatch_logged) begin
                display_signals("Specific Error Mismatch", r_in1, r_in2, r_in3, r_out_ref, r_out_dut, r_expected_out);
                first_mismatch_logged = 1;
            end
        end
    end
    
    // Timeout
    initial begin
        #1000000
        $display("
TIMEOUT: Simulation exceeded time limit.");
        $finish();
    end
    
    // Final Report
    final begin
        if (stats1.errors == 0 && stats1.errors_out == 0) begin
            $display("
=========================================");
            $display("SIMULATION PASSED");
            $display("=========================================");
        end else begin
            int total_mismatches = stats1.errors + stats1.errors_out;
            int first_time = 0;
            
            // Determine the earliest mismatch time
            if (stats1.errors == 0) first_time = stats1.errortime_out;
            else if (stats1.errors_out == 0) first_time = stats1.errortime;
            else first_time = (stats1.errortime < stats1.errortime_out) ? stats1.errortime : stats1.errortime_out;
            
            $display("
=========================================");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_time);
            $display("=========================================");
        end
        $display("Total clocks simulated: %0d", stats1.clocks);
    end

endmodule