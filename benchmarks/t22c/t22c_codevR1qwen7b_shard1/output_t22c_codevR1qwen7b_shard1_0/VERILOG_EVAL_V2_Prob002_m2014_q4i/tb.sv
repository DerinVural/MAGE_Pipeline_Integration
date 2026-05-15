`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1;
    wire out;
    logic out_ref;
    logic out_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    TopModule top_module1 ( .out(out) );
    RefModule good1 ( .out(out_ref) );
    // ... previous code for connections
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== out_ref ^ out_dut ^ out_ref) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    initial begin
        #1000000; $display("TIMEOUT"); $finish;
    end
endmodule