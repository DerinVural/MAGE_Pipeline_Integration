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
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a, b, c, d;
    logic out_ref, out_dut;
    wire tb_mismatch = ~(( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} )));
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    TopModule top_module1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out(out_dut)
    );
    RefModule good1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out(out_ref)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, d, out_ref, out_dut);
    end
    wire tb_match;
    assign tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} )));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out += 1;
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule

module stimulus_gen (
    input clk,
    output reg a,
    output reg b,
    output reg c,
    output reg d,
    output [511:0] wavedrom_title,
    output wavedrom_enable
);
    task wavedrom_start;
        input [511:0] title = "";
    endtask
    task wavedrom_stop;
        #1;
    endtask
    integer count;
    initial begin
        count = 0;
        {a, b, c, d} <= 4'b0;
        wavedrom_start();
        repeat(16) @(posedge clk) {a, b, c, d} <= count++;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {d, c, b, a} <= $urandom;
        #1 $finish;
    end
endmodule

module RefModule (
    input a,
    input b,
    input c,
    input d,
    output out
);
    // Replace with actual implementation
    assign out = ...;
endmodule