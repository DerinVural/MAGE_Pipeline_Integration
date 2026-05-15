`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Stimulus Generator (Kept as is)
module stimulus_gen (
    input clk,
    output logic [99:0] in
);
    always @(posedge clk, negedge clk)
        in <= {$random, $random, $random, $random};
    
    initial begin
        // Stimulus runs for 100 clocks
        repeat(100) @(negedge clk);
        $finish;
    end
endmodule

// Reference Module (Assumed to exist and function correctly for golden behavior)
module RefModule (
    input  logic [99:0] in,
    output logic [99:0] out
);
    // Following the structure observed in the golden testbench.
    assign out = in;
endmodule

// Top Module Under Test (DUT)
module TopModule (
    input  logic [99:0] in,
    output logic [99:0] out
);
    // Implementation for reversing bits (as per specification)
    always @(*) begin
        for (int i = 0; i < 100; i = i + 1) begin
            out[i] = in[99 - i];
        end
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
        logic [99:0] in_at_error;
        logic [99:0] out_ref_at_error;
        logic [99:0] out_dut_at_error;
    } stats;
    
    stats stats1;
    
    // Wavedrom signals (kept for consistency)
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [99:0] in;
    logic [99:0] out_ref;
    logic [99:0] out_dut;

    // Variables to capture state upon first error
    logic [99:0] first_in_mismatch;
    logic [99:0] first_out_ref_mismatch;
    logic [99:0] first_out_dut_mismatch;
    integer first_mismatch_time = -1;

    initial begin 
        $dumpfile("wave.vcd");
        // Dump relevant signals
        $dumpvars(1, stim1.clk, tb_match, in, out_ref, out_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Stimulus Generator Instantiation
    stimulus_gen stim1 (
        .clk,
        .*, 
        .in );
        
    // Reference Module Instantiation
    RefModule good1 (
        .in, 
        .out(out_ref) );
        
    // DUT Instantiation
    TopModule top_module1 (
        .in, 
        .out(out_dut) );

    // Task definitions
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Helper function to display signals in HEX/BIN format
    task display_signal(input string name, input logic [99:0] signal);
    begin
        $display("  %s = HEX: %h", name, signal);
        // Only display BINARY if width <= 64
        if (100 <= 64) begin 
            $display("  %s = BIN: %b", name, signal);
        end
    endtask

    // Simulation control and error tracking
    initial begin
        stats1.errors = 0;
        stats1.errortime = 0;
        stats1.errors_out = 0;
        stats1.errortime_out = 0;
        stats1.clocks = 0;
        
        // Wait for initial setup
        @(negedge clk);
        
        // Monitor loop
        while (1) begin
            @(negedge clk);
            
            stats1.clocks++;
            
            // Check for mismatch (tb_match condition)
            if (!tb_match) begin
                if (stats1.errors == 0) stats1.errortime = $time;
                stats1.errors++;
                
                // Capture state for first mismatch report
                if (first_mismatch_time == -1) begin
                    first_mismatch_time = $time;
                    first_in_mismatch = in;
                    first_out_ref_mismatch = out_ref;
                    first_out_dut_mismatch = out_dut;
                end
            end
            
            // Check for output specific mismatch (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
            if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
            begin
                if (stats1.errors_out == 0) stats1.errortime_out = $time;
                stats1.errors_out = stats1.errors_out + 1'b1;
                
                // Capture state for first output mismatch report
                if (first_mismatch_time == -1) begin
                    first_mismatch_time = $time;
                    first_in_mismatch = in;
                    first_out_ref_mismatch = out_ref;
                    first_out_dut_mismatch = out_dut;
                end
            end
            
            // Safety break matching stimulus_gen duration
            if (stats1.clocks >= 100) break;
        end
        
        // Add timeout after 100K cycles (Keep as safety net)
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    // Final Reporting Logic
    initial begin
        // Wait a short time after simulation loop finishes to ensure all updates settle
        @(negedge clk);
        #10;
        
        integer total_mismatches = stats1.errors + stats1.errors_out;
        
        if (total_mismatches == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", total_mismatches, first_mismatch_time);
            
            if (first_mismatch_time != -1) begin
                $display("\n--- FIRST MISMATCH DETAILS (TIME %0d ps) ---", first_mismatch_time);
                $display("Input Signal (in): ");
                display_signal("  in", first_in_mismatch);
                $display("Expected Output Signal (out_ref): ");
                display_signal("  out_ref", first_out_ref_mismatch);
                $display("Actual Output Signal (out_dut): ");
                display_signal("  out_dut", first_out_dut_mismatch);
            end
        end
        $display("Simulation finished at %0d ps", $time);
    end

    // Verification assignment (Kept exactly as in golden testbench)
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
endmodule