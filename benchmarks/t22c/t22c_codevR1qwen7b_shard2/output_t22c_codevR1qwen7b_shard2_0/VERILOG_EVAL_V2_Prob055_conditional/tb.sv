`timescale 1ps/1ps
module tb();
    // Inputs and outputs from golden testbench
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;
    logic [7:0] d;
    logic [7:0] min_ref;
    logic [7:0] min_dut;
    // Statistics
    typedef struct packed {
        int errors;
        int errortime;
        int errors_min;
        int errortime_min;
        int clocks;
    } stats;
    stats stats1;
    // Clock generation
    reg clk = 0;
    initial forever #5 clk = ~clk;
    // Stimulus generation module
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d)
    );
    // Reference module
    RefModule good1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .min(min_ref)
    );
    // DUT
    TopModule top_module1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .min(min_dut)
    );
    // Dumping variables
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, tb, a, b, c, d, min_ref, min_dut);
    end
    // Timeout after 1e6 cycles
    initial #1000000 $finish;
    // Wavedrom tasks - omitted for brevity
    // Simulation control
    wire tb_match = ( { min_ref } === ( { min_ref } ^ { min_dut } ^ { min_ref } ) );
    wire tb_mismatch = ~tb_match;
    // Error tracking
    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (min_ref !== ( min_ref ^ min_dut ^ min_ref )) begin
            if (stats1.errors_min == 0) stats1.errortime_min = $time;
            stats1.errors_min++;
        end
    end
    // Simulation end
    final begin
        if (stats1.errors_min) begin
            $display("Hint: Output 'min' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_min, stats1.errortime_min);
        end else begin
            $display("Hint: Output 'min' has no mismatches.");
        end
        $display("Hint: Total mismatched samples is %0d out of %0d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            if (stats1.errors > 0) begin
                $display("\nAt time %0d:\n", stats1.errortime);
                $display("a = %h (%b) | b = %h (%b) | c = %h (%b) | d = %h (%b) | min_dut = %h (%b) | min_ref = %h (%b)",
                    a, a, a, b, b, b, c, c, c, d, d, d, min_dut, min_dut, min_ref, min_ref);
            end
        end
    end
endmodule

module stimulus_gen (input clk, output logic [7:0] a, output logic [7:0] b, output logic [7:0] c, output logic [7:0] d);
    // Stimulus generation logic
    initial begin
        a = 8'h1;
        b = 8'h2;
        c = 8'h3;
        d = 8'h4;
        #10 a = 8'h11;
        #10 b = 8'h12;
        #10 c = 8'h13;
        #10 d = 8'h14;
        #10 $finish;
    end
endmodule