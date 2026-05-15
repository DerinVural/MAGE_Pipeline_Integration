`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output reg reset,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end
        if (srfail) $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail)) $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    task wavedrom_start(input [511:0] title = "" ); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        reset <= 1;
        wavedrom_start("Synchronous reset and counting");
        reset_test();
        repeat(12) @(posedge clk);
        wavedrom_stop();
        @(posedge clk);
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end
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
    stats stats1 = '0;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic reset;
    logic [3:0] q_ref, q_dut;
    wire tb_match = ~ (q_ref !== q_dut);
    wire tb_mismatch = q_ref !== q_dut;
    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .wavedrom_title(),
        .wavedrom_enable(),
        .tb_match(tb_match)
    );
    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .q(q_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .q(q_dut)
    );
    reg strobe = 0;
    task wait_for_end_of_timestep; repeat(5) strobe <= !strobe; @(strobe); endtask
    final begin
        if (stats1.errors_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Total mismatched samples: %0d out of %0d", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0t ps", $time);
    end
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== q_dut) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, q_ref, q_dut);
        reset <= 1;
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule