`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic do_sub,
    output logic [7:0] a,
    output logic [7:0] b,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input tb_match
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop(); #1; endtask
    initial begin
        {a, b} <= 16'haabb;
        do_sub <= 0;
        @(negedge clk); wavedrom_start();
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 1;
        @(posedge clk, negedge clk) do_sub <= 1;
        @(posedge clk, negedge clk) {a, b} <= 16'h0303; do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 1;
        @(posedge clk, negedge clk) {a, b} <= 16'h0304; do_sub <= 1;
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 1;
        @(posedge clk, negedge clk) {a, b} <= 16'hfd03; do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 1;
        @(posedge clk, negedge clk) {a, b} <= 16'hfd04; do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 0;
        @(posedge clk, negedge clk) do_sub <= 1;
        wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) {a, b, do_sub} <= $urandom;
        $finish;
    end
endmodule

module tb();
    typedef struct {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int errors_result_is_zero;
        int errortime_result_is_zero;
        int clocks;
    } stats;
    stats stats1 = 0;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic do_sub;
    logic [7:0] a, b;
    logic [7:0] out_ref, out_dut;
    logic result_is_zero_ref, result_is_zero_dut;
    logic [511:0] wavedrom_title;
    logic wavedrom_enable;
    wire tb_match = ~({out_ref, result_is_zero_ref} === {out_dut, result_is_zero_dut});
    stimulus_gen stim1 (
        .clk(clk),
        .do_sub(do_sub),
        .a(a),
        .b(b),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule refmod (
        .do_sub(do_sub),
        .a(a),
        .b(b),
        .out(out_ref),
        .result_is_zero(result_is_zero_ref)
    );
    TopModule dut (
        .do_sub(do_sub),
        .a(a),
        .b(b),
        .out(out_dut),
        .result_is_zero(result_is_zero_dut)
    );
    bit strobe = 0;
    task wait_for_stable();
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (stats1.errors == 0 && !tb_match) begin
            $display("First Mismatch at %0t: Expected out = %h (ref %h), result_is_zero=%b (ref %b) but got out = %h (dut %h), result_is_zero=%b (dut %b)",
                $time, out_ref, out_ref, result_is_zero_ref,
                out_dut, result_is_zero_dut);
            if (out_ref !== out_dut) begin
                $display("out: ref = %b, dut = %b", out_ref, out_dut);
                if (out_ref > 64) $display("out: ref = %b", out_ref);
                if (out_dut > 64) $display("out: dut = %b", out_dut);
            end
            if (result_is_zero_ref !== result_is_zero_dut) begin
                $display("result_is_zero: ref = %b, dut = %b", result_is_zero_ref, result_is_zero_dut);
            end
            stats1.errortime = $time;
        end
        if (!tb_match) stats1.errors++;
        if (out_ref !== out_dut) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
        if (result_is_zero_ref !== result_is_zero_dut) begin
            if (stats1.errors_result_is_zero == 0) stats1.errortime_result_is_zero = $time;
            stats1.errors_result_is_zero++;
        end
    end
    final begin
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule
