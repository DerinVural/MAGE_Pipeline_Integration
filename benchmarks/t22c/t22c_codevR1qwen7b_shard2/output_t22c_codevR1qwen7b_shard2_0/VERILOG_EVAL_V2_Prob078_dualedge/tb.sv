`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg d,
    output [511:0] wavedrom_title,
    output wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        d <= 0;
        @(negedge clk) wavedrom_start();
        repeat(20) @(posedge clk, negedge clk) d <= $random >> 2;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) d <= $random;
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    stats stats1 = 0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic d, q_ref, q_dut;
    RefModule good1 (clk, d, q_ref);
    TopModule top_module1 (clk, d, q_dut);
    wire tb_match = ({q_ref} === ({q_ref} ^ {q_dut} ^ {q_ref}));
    wire tb_mismatch = ~tb_match;
    assign tb_mismatch = ~tb_match;
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    final begin
        if (stats1.errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        else $display("SIMULATION PASSED");
        $display("Total errors: %0d in %0d samples", stats1.errors, stats1.clocks);
        $finish;
    end
endmodule