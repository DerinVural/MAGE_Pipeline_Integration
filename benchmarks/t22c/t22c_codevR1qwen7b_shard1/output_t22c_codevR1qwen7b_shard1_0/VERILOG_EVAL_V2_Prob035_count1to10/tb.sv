`timescale 1ps/1ps
module tb();
    reg clk = 0;
    reg reset = 1;
    logic [3:0] q_dut, q_ref;
    reg [3:1] expected;
    integer errors = 0, errortime = -1, clocks = 0;

    // Clock generation
    always #5 clk = ~clk;

    // DUT and reference
    TopModule dut (.clk(clk), .reset(reset), .q(q_dut));
    RefModule ref_mod (.clk(clk), .reset(reset), .q(q_ref));

    // Simulation control
    initial begin
        reset <= 0;
        #100;
        $finish;
    end

    // Monitoring and error counting
    always @(posedge clk) begin
        if (q_ref !== q_dut) begin
            if (errors == 0) errortime = $time;
            errors++;
            if (errors == 1) begin
                $display("Mismatch at time %0t: expected q=%h, got %h", $time, q_ref, q_dut);
            end
        end
        clocks++;
    end

    // Simulation status
    final begin
        if (errors == 0)
            $display("SIMULATION PASSED");
        else
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0t", errors, errortime);
    end

endmodule