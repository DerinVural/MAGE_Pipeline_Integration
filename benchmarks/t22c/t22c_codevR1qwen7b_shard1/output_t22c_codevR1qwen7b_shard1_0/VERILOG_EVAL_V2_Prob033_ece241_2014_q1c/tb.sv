`timescale 1ps/1ps

module stimulus_gen (
    input clk,
    output logic [7:0] a,
    output logic [7:0] b,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = "); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        {a, b} <= 0;
        @(negedge clk) wavedrom_start();
        @(posedge clk) {a, b} <= 16'h0;
        @(posedge clk) {a, b} <= 16'h0070;
        @(posedge clk) {a, b} <= 16'h7070;
        @(posedge clk) {a, b} <= 16'h7090;
        @(posedge clk) {a, b} <= 16'h9070;
        @(posedge clk) {a, b} <= 16'h9090;
        @(posedge clk) {a, b} <= 16'h90ff;
        @(negedge clk) wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) {a,b} <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_s;
        int errortime_s;
        int errors_overflow;
        int errortime_overflow;
        int clocks;
    } stats;
    stats stats1 = 0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] s_ref;
    logic [7:0] s_dut;
    logic overflow_ref;
    logic overflow_dut;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, s_ref, s_dut, overflow_ref, overflow_dut);
    end
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .a(a),
        .b(b),
        .s(s_ref),
        .overflow(overflow_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .a(a),
        .b(b),
        .s(s_dut),
        .overflow(overflow_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    final begin
        if (stats1.errors_s) $display("Hint: Output 's' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_s, stats1.errortime_s);
        else $display("Hint: Output 's' has no mismatches.");
        if (stats1.errors_overflow) $display("Hint: Output 'overflow' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_overflow, stats1.errortime_overflow);
        else $display("Hint: Output 'overflow' has no mismatches.");
        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0t ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    assign tb_match = ({s_ref, overflow_ref} === ({s_ref, overflow_ref} ^ {s_dut, overflow_dut} ^ {s_ref, overflow_ref})));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (s_ref !== (s_ref ^ s_dut ^ s_ref)) begin
            if (stats1.errors_s == 0) stats1.errortime_s = $time;
            stats1.errors_s++;
        end
        if (overflow_ref !== (overflow_ref ^ overflow_dut ^ overflow_ref)) begin
            if (stats1.errors_overflow == 0) stats1.errortime_overflow = $time;
            stats1.errors_overflow++;
        end
    end
    initial begin #1000000 $display("TIMEOUT"); $finish(); end
endmodule