// Testbench adjusted for syntax
`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic resetn,
    output logic x,
    output logic y
);
    initial begin
        resetn = 0;
        x = 0;
        y = 0;
        @(posedge clk);
        @(posedge clk);
        resetn = 1;
        repeat(500) @(negedge clk) begin
            resetn <= ($random & 31) != 0;
            {x,y} <= $random;
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_f;
        int errortime_f;
        int errors_g;
        int errortime_g;
        int clocks;
    } stats;

    stats stats1 = '{errors:0, errortime:0, errors_f:0, errortime_f:0, errors_g:0, errortime_g:0, clocks:0};

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic resetn;
    logic x;
    logic y;
    logic f_ref;
    logic f_dut;
    logic g_ref;
    logic g_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, resetn, x, y, f_ref, f_dut, g_ref, g_dut);
    end

    wire tb_match, tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .resetn(resetn),
        .x(x),
        .y(y)
    );

    RefModule good1 (
        .clk(clk),
        .resetn(resetn),
        .x(x),
        .y(y),
        .f(f_ref),
        .g(g_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .resetn(resetn),
        .x(x),
        .y(y),
        .f(f_dut),
        .g(g_dut)
    );

    reg strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (f_ref !== (f_ref ^ f_dut ^ f_ref)) begin
            if (stats1.errors_f == 0) stats1.errortime_f = $time;
            stats1.errors_f++;
        end
        if (g_ref !== (g_ref ^ g_dut ^ g_ref)) begin
            if (stats1.errors_g == 0) stats1.errortime_g = $time;
            stats1.errors_g++;
        end
    end

    initial begin #1000000; $display("TIMEOUT"); $finish; end

    final begin
        $display("");
        if (stats1.errors_f) $display("Hint: Output 'f' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_f, stats1.errortime_f);
        else $display("Hint: Output 'f' has no mismatches.");
        if (stats1.errors_g) $display("Hint: Output 'g' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_g, stats1.errortime_g);
        else $display("Hint: Output 'g' has no mismatches.");
        $display("Total mismatched samples: %0d out of %0d\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("Input signals: resetn=%b, x=%b, y=%b\nOutput signals: f_ref=%b, g_ref=%b\nExpected outputs: f_dut=%b, g_dut=%b",
                stats1.errortime, resetn, x, y,
                stats1.errortime, f_ref, g_ref, f_dut, g_dut);
            $display("HEX: resetn=%h, x=%h, y=%h", resetn, x, y);
            $display("BINARY: resetn=%b, x=%b, y=%b\n", resetn, x, y);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule