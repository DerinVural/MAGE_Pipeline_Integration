`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Required supporting modules (Minimal definitions based on golden testbench structure) ---

module RefModule (
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    input logic e,
    output logic [24:0] out
);
    // Placeholder implementation for RefModule. In a real scenario, this would implement the correct logic.
    assign out = 25'b0;
endmodule

module stimulus_gen (
    input logic clk,
    output logic a, b, c, d, e
);
    initial begin
        repeat(100) @(posedge clk, negedge clk)
            {a,b,c,d,e} <= $random;
        $finish;
    end
endmodule

// --- Enhanced Testbench ---
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    
    stats stats1;
    
    // Variables to capture state at the FIRST mismatch
    logic [24:0] first_mismatch_dut_out;
    logic [24:0] first_mismatch_ref_out;
    logic [4:0] first_mismatch_inputs;
    int first_mismatch_time;
    
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
    logic e;
    logic [24:0] out_ref;
    logic [24:0] out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        // Dump variables covering all instantiated modules and testbench signals
        $dumpvars(1, stimulus_gen::stim1, tb);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e)
    );
    
    // Instantiate Reference Module
    RefModule good1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .out(out_ref)
    );
    
    // Instantiate DUT
    TopModule top_module1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .out(out_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Task to display details of a multi-bit vector (<= 64 bits)
    task display_vector;
        input logic [24:0] vec;
        input string name;
        begin
            // Display in HEX and BINARY format
            $display("%-25s: HEX=%h, BIN=%b", name, vec, vec);
        end
    endtask

    final begin
        if (stats1.errors == 0) begin
            $display("
=====================================");
            $display("SIMULATION PASSED");
            $display("=====================================");
            $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
            $display("Simulation finished at %0d ps", $time);
        end
        else begin
            $display("
=====================================");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("--------------------------------------");
            $display("--- FIRST MISMATCH DETAILS ---");
            $display("Inputs: a=%b, b=%b, c=%b, d=%b, e=%b", a, b, c, d, e);
            display_vector(out_dut, "DUT Output (out)");
            display_vector(out_ref, "Expected Output (out_ref)");
            $display("--------------------------------------");
            $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
            $display("Simulation finished at %0d ps", $time);
        end
    end

    // Verification check
    // This uses the XOR trick: (A === (A ^ B ^ A)) is equivalent to A === B
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Clocked logic for error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Capture state at first mismatch
                first_mismatch_time = $time;
                first_mismatch_dut_out = out_dut;
                first_mismatch_ref_out = out_ref;
                first_mismatch_inputs = {a, b, c, d, e};
            end
            stats1.errors++;
        end
        
        // Original logic for errors_out (kept for compatibility, corrected variable name)
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out+1'b1;
        end
    end

    // Add timeout after 100K cycles
    initial begin
        #1000000
        $display("
TIMEOUT REACHED");
        $finish();
    end

endmodule