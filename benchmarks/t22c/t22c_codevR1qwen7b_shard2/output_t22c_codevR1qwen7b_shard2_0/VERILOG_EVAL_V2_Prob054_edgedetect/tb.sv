`timescale 1ps/1ps
module stimulus_gen (input clk, input tb_match, output reg [7:0] in, output [511:0] wavedrom_title, output reg wavedrom_enable);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        in <= 0;
        @(posedge clk);
        wavedrom_start();
        repeat(2) @(posedge clk);
        in <= 1;
        repeat(4) @(posedge clk);
        in <= 0;
        repeat(4) @(negedge clk);
        in <= 6;
        repeat(2) @(negedge clk);
        in <= 0;
        repeat(2) @(posedge clk);
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) in <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_pedge;
        int errortime_pedge;
        int clocks;
    } stats;
    stats stats1;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [7:0] in;
    logic [7:0] pedge_ref;
    logic [7:0] pedge_dut;
    logic tb_match;
    logic tb_mismatch = ~tb_match;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, in, pedge_ref, pedge_dut);
    end

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
        .pedge(pedge_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .pedge(pedge_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    final begin
        if (stats1.errors_pedge) begin
            $display("Hint: Output 'pedge' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_pedge, stats1.errortime_pedge);
        end else begin
            $display("Hint: Output 'pedge' has no mismatches.");
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0 && stats1.errors_pedge == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    // Verification logic
    assign tb_match = ( {pedge_ref} === ( {pedge_ref} ^ {pedge_dut} ^ {pedge_ref} ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (pedge_ref !== ( pedge_ref ^ pedge_dut ^ pedge_ref )) begin
            if (stats1.errors_pedge == 0) stats1.errortime_pedge = $time;
            stats1.errors_pedge++;
        end
    end
endmodule