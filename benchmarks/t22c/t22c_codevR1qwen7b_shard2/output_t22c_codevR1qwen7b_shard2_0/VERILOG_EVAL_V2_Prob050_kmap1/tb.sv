`timescale 1ps/1ps
module tb();
    reg clk;
    logic a, b, c, out_dut, out_ref;
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1;
    wire tb_match;
    assign tb_match = (out_ref === (out_ref ^ out_dut ^ out_ref));

    // Stimulus generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Module instantiation
    TopModule dut (.a(a), .b(b), .c(c), .out(out_dut));
    RefModule ref (.a(a), .b(b), .c(c), .out(out_ref));

    // Error checking
    initial begin
        stats1 = '{errors:0, errortime:0, errors_out:0, errortime_out:0, clocks:0};
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, a, b, c, out_ref, out_dut);
    end

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

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors_out > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule