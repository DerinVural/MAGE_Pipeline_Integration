`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg a, b
);
    task wavedrom_start(input[511:0] title = "NOR gate"); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        int count; count = 0;
        {a,b} <= 1'b0;
        wavedrom_start("NOR gate");
        repeat(10) @(posedge clk) {a,b} <= count++;
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {b,a} <= $random;
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
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a; logic b; logic out_ref; logic out_dut;
    wire tb_match;
    reg tb_mismatch;
    assign tb_mismatch = ~tb_match;
    stimulus_gen stim1 ( .clk(clk), .a(a), .b(b) );
    RefModule good1 ( .a(a), .b(b), .out(out_ref) );
    TopModule top_module1 ( .a(a), .b(b), .out(out_dut) );
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, out_ref, out_dut);
    end
    assign tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    initial begin #1000000; $display("TIMEOUT"); $finish(); end
    final begin
        if (stats1.errors_out) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else $display("SIMULATION PASSED");
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
endmodule