`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_assign;
        int errortime_out_assign;
        int errors_out_alwaysblock;
        int errortime_out_alwaysblock;
        int clocks;
    } stats;
    stats stats1 = {0, 0, 0, 0, 0, 0, 0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a;
    logic b;
    logic out_assign_ref;
    logic out_assign_dut;
    logic out_alwaysblock_ref;
    logic out_alwaysblock_dut;
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
        .out_assign(out_assign_ref),
        .out_alwaysblock(out_alwaysblock_ref)
    );
    TopModule top_module1 (
        .a(a),
        .b(b),
        .out_assign(out_assign_dut),
        .out_alwaysblock(out_alwaysblock_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_assign_ref !== (out_assign_ref ^ out_assign_dut ^ out_assign_ref)) begin
            if (stats1.errors_out_assign == 0) stats1.errortime_out_assign = $time;
            stats1.errors_out_assign++;
        end
        if (out_alwaysblock_ref !== (out_alwaysblock_ref ^ out_alwaysblock_dut ^ out_alwaysblock_ref)) begin
            if (stats1.errors_out_alwaysblock == 0) stats1.errortime_out_alwaysblock = $time;
            stats1.errors_out_alwaysblock++;
        end
    end
    if (stats1.errors > 0) begin
        $display("First Mismatch at time %0d", stats1.errortime);
        $display("Input a: %b, Input b: %b", a, b);
        $display("Output out_assign_ref: %b, out_assign_dut: %b", out_assign_ref, out_assign_dut);
        $display("Output out_alwaysblock_ref: %b, out_alwaysblock_dut: %b", out_alwaysblock_ref, out_alwaysblock_dut);
    end
    final begin
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            if (stats1.errors_out_assign) $display("Hint: Output 'out_assign' has %0d mismatches. First occurred at time %0d", stats1.errors_out_assign, stats1.errortime_out_assign);
            if (stats1.errors_out_alwaysblock) $display("Hint: Output 'out_alwaysblock' has %0d mismatches. First occurred at time %0d", stats1.errors_out_alwaysblock, stats1.errortime_out_alwaysblock);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    initial begin #1000000; $display("TIMEOUT"); $finish; end
endmodule

module stimulus_gen (
    input clk,
    output reg a,
    output reg b,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask;
    task wavedrom_stop; #1; endtask;
    integer count;
    initial begin
        count = 0;
        {a, b} = 2'b0;
        wavedrom_start("AND gate");
        repeat(10) @(posedge clk) {a, b} = count++;
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {b, a} = $random;
        #1 $finish;
    end
endmodule