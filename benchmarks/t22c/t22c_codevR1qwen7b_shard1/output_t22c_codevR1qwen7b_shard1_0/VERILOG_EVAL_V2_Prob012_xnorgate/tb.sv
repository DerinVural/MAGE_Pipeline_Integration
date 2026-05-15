`timescale 1ps/1ps
module tb();
    typedef struct packed {
        integer errors;
        integer errortime;
        integer errors_out;
        integer errortime_out;
    } stats;
    stats stats1 = '0;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a, b;
    logic out_ref, out_dut;
    reg strobe = 0;
    task wait_for_stable(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    // Clock generation and stimulus
    initial begin
        stats1.clocks = 0;
        stats1.errors = 0;
        stats1.errortime = -1;
        stats1.errors_out = 0;
        stats1.errortime_out = -1;
        wait_for_stable();
        // Stimulus phase
        repeat(10) @(posedge clk) begin
            a <= 1'b0;
            b <= 1'b0;
        end
        repeat(200) @(posedge clk) begin
            a <= $urandom;
            b <= $urandom;
        end
        #1 $finish;
    end
    // Reference output
    assign out_ref = a ~^ b;
    // Instantiate DUT
    TopModule top_inst (.a(a), .b(b), .out(out_dut));
    // Check for mismatches
    always @(posedge clk) begin
        stats1.clocks++;
        if (out_ref !== out_dut) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("SIMULATION FAILED - 1 MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
                $display("a: %b, b: %b, Expected: %b, Actual: %b", a, b, out_ref, out_dut);
            end
            stats1.errors++;
        end
        if (out_dut !== (a ~^ b)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    // Timeout
    initial begin
        #1000000 $display("TIMEOUT"); $finish;
    end
    // Simulation end
    final begin
        if (stats1.errors) begin
            if (stats1.errors > 1) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            else $display("SIMULATION FAILED - 1 MISMATCH DETECTED AT TIME %0d", stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule