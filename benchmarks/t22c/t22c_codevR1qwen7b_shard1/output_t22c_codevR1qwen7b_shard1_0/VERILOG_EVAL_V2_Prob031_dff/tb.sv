`timescale 1ps/1ps
module tb();
    typedef struct {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    stats stats1;
    reg clk = 0;
    logic d;
    logic q_ref;
    logic q_dut;
    initial forever #5 clk = ~clk;
    RefModule good1 (.clk(clk), .d(d), .q(q_ref));
    TopModule top_module1 (.clk(clk), .d(d), .q(q_dut));
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, d, q_ref, q_dut);
    end
    wire tb_match = (q_ref === (q_ref ^ q_dut ^ q_ref));
    wire tb_mismatch = ~tb_match;
    integer error_count = 0, error_time = 0;
    integer error_count_q = 0, error_time_q = 0;
    integer clock_count = 0;
    always @(posedge clk) begin
        clock_count++;
        if (!tb_match) begin
            if (error_count == 0) error_time = $time;
            error_count++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (error_count_q == 0) error_time_q = $time;
            error_count_q++;
        end
    end
    initial begin
        d = 0;
        #10 d = 1;
        #10 d = 0;
        #1000 $finish;
    end
    initial begin
        @(posedge clk);
        repeat(2) @(posedge clk);
        if (error_count || error_count_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", error_count, error_time);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", error_count, clock_count);
    end
endmodule