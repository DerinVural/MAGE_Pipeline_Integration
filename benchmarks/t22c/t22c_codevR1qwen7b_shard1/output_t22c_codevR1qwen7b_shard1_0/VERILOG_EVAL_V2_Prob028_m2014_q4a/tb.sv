`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic d, ena
);
    initial begin
        repeat(100) @(posedge clk, negedge clk) {d, ena} <= $random;
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
    stats stats1 = '{errors:0, errortime:0, errors_q:0, errortime_q:0, clocks:0};
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic d;
    logic ena;
    logic q_ref;
    logic q_dut;
    wire tb_mismatch = (q_ref !== q_dut);
    stimulus_gen stim1 (
        .clk(clk),
        .d(d),
        .ena(ena)
    );
    RefModule gm (
        .d(d),
        .ena(ena),
        .q(q_ref)
    );
    TopModule top_module1 (
        .d(d),
        .ena(ena),
        .q(q_dut)
    );
    bit strobe = 0;
    task wait_for_strobe();
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    always @(posedge clk) begin
        stats1.clocks++;
        if (tb_mismatch) begin
            stats1.errors++;
            if (stats1.errors == 1) stats1.errortime = $time;
        end
        if (q_ref !== q_dut) begin
            stats1.errors_q++;
            if (stats1.errors_q == 1) stats1.errortime_q = $time;
        end
    end
    initial begin
        #1000000; $display("TIMEOUT"); $finish();
    end
    initial begin
        wait_for_strobe();
        if (stats1.errors) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        else $display("SIMULATION PASSED");
        $finish();
    end
endmodule