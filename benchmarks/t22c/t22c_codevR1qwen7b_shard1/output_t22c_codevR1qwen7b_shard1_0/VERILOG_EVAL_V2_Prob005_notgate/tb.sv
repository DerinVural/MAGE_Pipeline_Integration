module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1;
    logic in;
    logic out_dut;
    logic out_ref;
    wire tb_match;

    // Instantiate DUT
    TopModule top_module1 (.in(in), .out(out_dut));
    RefModule ref_module1 (.in(in), .out(out_ref));

    // Clock generation
    reg clk = 0;
    always #5 clk = ~clk;

    // Error checking
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

    // Simulation control
    initial begin
        in = 0;
        #1000000; // Timeout after 500,000 time units
        $finish;
    end

    // Simulation end message
    final begin
        if (stats1.errors_out)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else
            $display("SIMULATION PASSED");
        if (stats1.errors > 0 && stats1.errortime != 0)
            $display("First Mismatch at time %0d: in=%b out=%b expected=%b", stats1.errortime, in, out_dut, out_ref);
    end
endmodule

module RefModule (input in, output out);
    assign out = ~in;
endmodule