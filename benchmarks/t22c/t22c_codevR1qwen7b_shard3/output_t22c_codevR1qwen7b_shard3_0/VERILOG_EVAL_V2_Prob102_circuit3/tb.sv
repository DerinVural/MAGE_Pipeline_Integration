`timescale 1ps/1ps
module tb();
    logic a, b, c, d;
    logic q_dut;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    stats stats1;
    initial begin
        {a, b, c, d} = 0;
        @(negedge clk);
        repeat(18) @(posedge clk, negedge clk) {a, b, c, d} += 1;
    end
    TopModule dut ( .a(a), .b(b), .c(c), .d(d), .q(q_dut) );
    wire tb_mismatch = ~((0 === (0 ^ q_dut ^ 0)));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (0 !== (0 ^ q_dut ^ 0)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    initial #1000000 $display("TIMEOUT");
    final begin
        if (stats1.errors_q == 0) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        $display("a=%b, b=%b, c=%b, d=%b, q_dut=%b", a, b, c, d, q_dut);
        $finish;
    end
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, tb);
    end
endmodule

struct packed stats {
    int errors;
    int errortime;
    int errors_q;
    int errortime_q;
    int clocks;
};