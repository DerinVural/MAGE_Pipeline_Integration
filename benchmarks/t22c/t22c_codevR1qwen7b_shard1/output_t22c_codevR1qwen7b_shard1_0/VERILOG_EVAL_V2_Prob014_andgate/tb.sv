`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;

    stats stats1();
    wire tb_mismatch;
    reg clk = 0;
    logic a;
    logic b;
    logic out_ref;
    logic out_dut;

    // Clock generation
    initial forever #5 clk = ~clk;

    // Stimulus module
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .wavedrom_title(),
        .wavedrom_enable()
    );

    // Reference module and DUT
    RefModule good1 (.a(a), .b(b), .out(out_ref));
    TopModule top_module1 (.a(a), .b(b), .out(out_dut));

    // Timeout after 100k cycles
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end

    // Error checking
    assign tb_mismatch = (out_ref !== out_dut);

    always @(posedge clk, negedge clk) begin
        stats1.clocks += 1;
        if (tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors += 1;
        end
        if (out_ref !== out_dut) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out += 1;
        end
    end

    // Simulation end display
    final begin
        if (stats1.errors_out)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else
            $display("SIMULATION PASSED");
        if (stats1.errors)
            $display("First mismatch at %0d", stats1.errortime);
    end
endmodule

module stimulus_gen (input clk, output logic a, output logic b);
    task wavedrom_start(input[511:0] title = "" ); endtask
    task wavedrom_stop(); #1; endtask
    initial begin
        int count = 0;
        {a,b} <= 1'b0;
        wavedrom_start("AND gate");
        repeat(10) @(posedge clk) {a,b} <= count++;
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {b,a} <= $random;
        #1 $finish;
    end
endmodule
module RefModule (input a, input b, output out); assign out = a & b; endmodule
