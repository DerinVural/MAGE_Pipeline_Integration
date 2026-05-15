`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic [2:0] a,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) a <= 0;
        repeat(10) @(posedge clk, negedge clk) a <= a + 1;
        wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) a <= $urandom;
        $finish;
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
    stats stats1 = '{errors:0, errortime:0, errors_q:0, errortime_q:0, clocks:0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [2:0] a;
    logic [15:0] q_ref, q_dut;
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1 (.*);
    RefModule good1 (.a(a), .q(q_ref));
    TopModule top_module1 (.a(a), .q(q_dut));
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    final begin
        if (stats1.errors_q) $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output 'q' has no mismatches.");
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
    end
    assign tb_match = (q_ref === (q_ref ^ q_dut ^ q_ref));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    initial #1000000 $display("TIMEOUT"); $finish();
endmodule