`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

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
        @(negedge clk) begin datafail = !tb_match ; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        reset <= 1;
        @(negedge clk);
        wavedrom_start();
        reset_test();
        repeat(8) @(posedge clk);
        @(negedge clk);
        wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end
        @(posedge clk) reset <= 1'b0;
        repeat(2000) @(posedge clk);
        reset <= 1'b1;
        repeat(5) @(posedge clk);
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
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    integer wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic reset;
    logic [4:0] q_ref;
    logic [4:0] q_dut;
    wire tb_match = ~(( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } )));
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
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
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    final begin
        if (stats1.errors_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule