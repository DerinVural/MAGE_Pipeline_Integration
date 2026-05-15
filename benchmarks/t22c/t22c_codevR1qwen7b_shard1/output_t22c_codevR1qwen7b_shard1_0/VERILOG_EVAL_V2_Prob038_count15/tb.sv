`timescale 1ps/1ps

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;

    stats stats1 = stats'(0);
    reg clk = 0;
    logic reset;
    logic [3:0] q_ref;
    logic [3:0] q_dut;
    wire tb_match = ( {q_ref} === ( {q_ref} ^ {q_dut} ^ {q_ref} ) );

    // Dump variables for waveform viewer
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, reset, q_ref, q_dut);
    end

    // Clock generation
    initial forever #5 clk = ~clk;

    // Instantiate modules
    stimulus_gen stim1 (.*);
    RefModule good1 (.*);
    TopModule top_module1 (.*);

    bit strobe = 0;
    task wait_for_end_of_timestep();
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    // Simulation control
    initial begin
        // Initialize reference and dut signals
        q_ref = 0;
        q_dut = 0;
        reset = 1;
        @(negedge clk);

        // Test reset and counting
        // (Assuming stimulus_gen handles the actual test cases)
    end

    // Error counting
    final begin
        if (stats1.errors_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Simulation finished at %0d", $time);
    end

    // Track errors
    always @(posedge clk, negedge clk) begin
        stats1.clocks += 1;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors += 1;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q += 1;
        end
    end

    // Timeout after 1e6 time units
    initial #1e6 $display("TIMEOUT") & $finish();
endmodule

module stimulus_gen (
    input clk,
    output reg reset,
    input tb_match,
    output reg wavedrom_enable,
    output reg [511:0] wavedrom_title
);
    // Wavedrom tasks omitted for brevity
    initial begin
        reset = 1;
        @(negedge clk);
        // Add test cases as needed
        $finish;
    end
endmodule

RefModule good1 (
    input clk,
    input reset,
    output [3:0] q
); // Reference module not implemented