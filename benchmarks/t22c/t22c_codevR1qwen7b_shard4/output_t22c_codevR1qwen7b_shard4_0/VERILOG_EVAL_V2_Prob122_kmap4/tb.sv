`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg a, b, c, d,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask

    initial begin
        int count; count = 0;
        {a, b, c, d} <= 4'b0;
        wavedrom_start();
        repeat(16) @(posedge clk) {a, b, c, d} <= count++;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {d, c, b, a} <= $urandom;
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;

    stats stats1;

    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic a, b, c, d;
    logic out_ref, out_dut;
    wire tb_match = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .a(a), .b(b), .c(c), .d(d),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    RefModule good1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out(out_ref)
    );

    TopModule top_module1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out(out_dut)
    );

    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end

    initial begin #1000000 $display("TIMEOUT"); $finish(); end

    final begin
        if (stats1.errors_out) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else $display("SIMULATION PASSED");
        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0t ps", $time);
    end
endmodule