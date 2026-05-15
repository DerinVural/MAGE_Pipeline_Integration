`timescale 1 ps/1 ps
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
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
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

    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask

    initial begin
        reset <= 1;
        wavedrom_start("Synchronous reset");
        reset_test();
        repeat(5) @(posedge clk);
        wavedrom_stop();
        reset <= 0;
        repeat(989) @(negedge clk);
        wavedrom_start("Wrap around behaviour");
        repeat(14) @(posedge clk);
        wavedrom_stop();
        repeat(2000) @(posedge clk, negedge clk) reset <= !($random & 127);
        reset <= 0;
        repeat(2000) @(posedge clk);
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
    stats stats1;

    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    logic clk;
    initial forever #5 clk = ~clk;
    logic reset;
    logic [9:0] q_ref;
    logic [9:0] q_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;

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

    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    // Error counting
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

    // Display on timeout
    initial begin
        #1000000 $display("TIMEOUT");
        $finish();
    end

    // Simulation end
    final begin
        if (stats1.errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        else $display("SIMULATION PASSED");
        $display("First mismatch occurred at time %0d", stats1.errortime);
        $display("Total mismatched samples: %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
endmodule