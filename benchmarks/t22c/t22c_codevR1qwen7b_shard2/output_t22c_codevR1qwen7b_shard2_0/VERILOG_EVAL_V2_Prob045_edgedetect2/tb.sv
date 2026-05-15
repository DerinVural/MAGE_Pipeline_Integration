`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    input tb_match,
    output reg [7:0] in,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask

    initial begin
        in <= 0;
        @(posedge clk);
        @(negedge clk) wavedrom_start("");
        repeat(2) @(posedge clk);
        in <= 1;
        repeat(4) @(posedge clk);
        in <= 0;
        repeat(4) @(negedge clk);
        in <= 6;
        repeat(2) @(negedge clk);
        in <= 0;
        repeat(2) @(posedge clk);
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) in <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_anyedge;
        int errortime_anyedge;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [7:0] in;
    logic [7:0] anyedge_ref;
    logic [7:0] anyedge_dut;

    wire tb_match = ~({ anyedge_ref } === ( { anyedge_ref } ^ { anyedge_dut } ^ { anyedge_ref } ));
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .tb_match(tb_match),
        .in(in),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .clk(clk),
        .in(in),
        .anyedge(anyedge_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .anyedge(anyedge_dut)
    );

    task wait_for_end_of_timestep; reg strobe = 0; repeat(5) begin strobe <= !strobe; @(strobe); end endtask

    always @(posedge clk, negedge clk) begin stats1.clocks++; end

    always @(posedge clk) begin
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (anyedge_ref !== ( anyedge_ref ^ anyedge_dut ^ anyedge_ref )) begin
            if (stats1.errors_anyedge == 0) stats1.errortime_anyedge = $time;
            stats1.errors_anyedge++;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, in, anyedge_ref, anyedge_dut);
        #1000000 $display("TIMEOUT"); $finish;
    end

    final begin
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        if (stats1.errors_anyedge) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d\n", stats1.errors_anyedge, stats1.errortime_anyedge);
        else $display("SIMULATION PASSED");
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) begin
            $display("First Mismatch Detected At Time %0d:\n", stats1.errortime);
            $display("CLK = %b, IN = %b, ANYEDGE_DUT = %b, ANYEDGE_REF = %b\n", clk, in, anyedge_dut, anyedge_ref);
            if (anyedge_dut <=64) $display("(Binary: CLK = %b, IN = %b, ANYEDGE_DUT = %b, ANYEDGE_REF = %b)\n", clk, in, anyedge_dut, anyedge_ref);
        end
    end
endmodule