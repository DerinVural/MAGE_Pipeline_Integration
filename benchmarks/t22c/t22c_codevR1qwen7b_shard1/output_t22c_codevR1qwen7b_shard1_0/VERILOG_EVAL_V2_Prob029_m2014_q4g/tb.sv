`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1 = 0;
    logic clk = 0;
    initial forever #5 clk = ~clk;
    logic in1, in2, in3;
    logic out_ref, out_dut;
    wire tb_match;
    wire tb_mismatch;

    stimulus_gen stim1 (
        .clk(clk),
        .in1(in1),
        .in2(in2),
        .in3(in3)
    );
    RefModule good1 (
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .out(out_ref)
    );
    TopModule top_module1 (
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .out(out_dut)
    );

    assign tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) );
    assign tb_mismatch = ~tb_match;

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end

    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end

    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
            $display("Time %0t: in1=%b, in2=%b, in3=%b, out=%b, expected %b", $time, in1, in2, in3, out_dut, out_ref);
        end else if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("Time %0t: in1=%b, in2=%b, in3=%b, out=%b, expected %b", $time, in1, in2, in3, out_dut, out_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule

module stimulus_gen (
    input clk,
    output logic in1,
    output logic in2,
    output logic in3
);
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            {in1, in2, in3} <= $random;
        end
        #1 $finish;
    end
endmodule