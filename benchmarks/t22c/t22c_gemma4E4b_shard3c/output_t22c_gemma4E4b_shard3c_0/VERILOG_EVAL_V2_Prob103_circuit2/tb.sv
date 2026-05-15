`timescale 1 ps/1 ps

// Constants matching the golden testbench
`define OK 12
`define INCORRECT 13

// --- Stimulus Generator Module (Copied from Golden TB) ---
module stimulus_gen (
    input clk,
    output logic a,b,c,d,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    // Add two ports to module stimulus_gen:
    //    output [511:0] wavedrom_title
    //    output reg wavedrom_enable

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask


    initial begin
        {a,b,c,d} <= 0;
        @(negedge clk) wavedrom_start("Unknown circuit");
            @(posedge clk) {a,b,c,d} <= 0;
            repeat(18) @(posedge clk, negedge clk) {a,b,c,d} <= {a,b,c,d} + 1;
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk)
            {a,b,c,d} <= $urandom;
        $finish;
    end
    
endmodule

module RefModule (
    input a,
    input b,
    input c,
    input d,
    output q
);
    // Implementation based on the truth table derived from input_spec
    // (0000)->1, (0001)->0, (0010)->0, (0011)->1, (0100)->0, (0101)->1, (0110)->1, (0111)->0,
    // (1000)->0, (1001)->1, (1010)->1, (1011)->0, (1100)->1, (1101)->0, (1110)->0, (1111)->1
    
    assign q = (a==0 && b==0 && c==0 && d==0) || 
                (a==0 && b==0 && c==1 && d==1) || 
                (a==0 && b==1 && c==0 && d==1) || 
                (a==0 && b==1 && c==1 && d==0) || 
                (a==1 && b==0 && c==0 && d==1) || 
                (a==1 && b==0 && c==1 && d==0) || 
                (a==1 && b==1 && c==0 && d==0) || 
                (a==1 && b==1 && c==1 && d==1);

endmodule

// --- DUT Module (TopModule) ---
module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);
    // Combinational circuit implementation matching the specified waveforms
    assign q = (a==0 && b==0 && c==0 && d==0) || 
                (a==0 && b==0 && c==1 && d==1) || 
                (a==0 && b==1 && c==0 && d==1) || 
                (a==0 && b==1 && c==1 && d==0) || 
                (a==1 && b==0 && c==0 && d==1) || 
                (a==1 && b==0 && c==1 && d==0) || 
                (a==1 && b==1 && c==0 && d==0) || 
                (a==1 && b==1 && c==1 && d==1);
endmodule

// --- Testbench Module ---
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

    logic a;
    logic b;
    logic c;
    logic d;
    logic q_ref; // Expected output from RefModule
    logic q_dut; // Output from DUT (TopModule)

    // Variables to capture first mismatch details
    integer first_mismatch_time = 0;
    logic mismatch_q_captured = 0;

    initial begin 
        $dumpfile("wave.vcd");
        // Dump vars scoped to the instance in stimulus_gen
        $dumpvars(1, stimulus_gen::stim1, a,b,c,d,q_ref,q_dut );
    end

    
    wire tb_match;         // Verification
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator
    stimulus_gen stim1 (
        .clk,
        .* , 
        .a,
        .b,
        .c,
        .d );
    
    // Instantiate Reference Model
    RefModule good1 (
        .a,
        .b,
        .c,
        .d,
        .q(q_ref) );
        
    // Instantiate DUT
    TopModule top_module1 (
        .a,
        .b,
        .c,
        .d,
        .q(q_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Verification: Simplified for 1-bit comparison, maintaining original intent.
    assign tb_match = ( q_ref === ( q_ref ^ q_dut ^ q_ref ) ); 
    
    // Clocked logic for stats and mismatch detection
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        // 1. General Mismatch Counting (Original Logic)
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // 2. Output 'q' Mismatch Counting (Original Logic)
        if (q_ref !== q_dut)
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1; 

            // Capture details ONLY on the very first 'q' mismatch
            if (stats1.errors_q == 1 && !mismatch_q_captured) begin
                first_mismatch_time = $time;
                mismatch_q_captured = 1;
            end
        end

    end

    // --- FINALIZATION BLOCK (IMPROVED DISPLAY) ---
    final begin
        
        // NEW REQUIREMENT 1: Overall Pass/Fail Display
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
        
        // NEW REQUIREMENT 2: Detailed display for the FIRST 'q' mismatch if it occurred
        if (stats1.errors_q > 0 && first_mismatch_time > 0) begin
            $display("
--- FIRST 'Q' MISMATCH DETAILS (Time: %0d ps) ---", first_mismatch_time);
            // Display inputs (all 1-bit, so binary is sufficient)
            $display("Input Signals (a, b, c, d): %b, %b, %b, %b", a, b, c, d);
            // Display outputs
            $display("Output Signals (q_DUT, q_REF): %b, %b", q_dut, q_ref);
            $display("--------------------------------------------------");
        end
        
        // Retain original summary display
        $display("
Total mismatched samples (General): %1d out of %1d samples", stats1.errors, stats1.clocks);
        $display("Total 'q' mismatches: %1d out of %1d samples", stats1.errors_q, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    
    // Add timeout after 100K cycles
    initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
    end

endmodule