`timescale 1ps/1ps
module tb();
    logic clk;
    reg [3:0] a, b, c, d, e;
    logic [3:0] q_ref, q_dut;
    logic [511:0] wavedrom_title;
    logic wavedrom_enable;
    initial clk = 0;
    always #5 clk = ~clk;
    TopModule top_module1(a, b, c, d, e, q_dut);
    RefModule good1(a, b, c, d, e, q_ref);
    // Error checking logic
    integer errors, errortime, clocks;
    initial begin
        errors = 0;
        errortime = 0;
        clocks = 0;
        // Your test sequence
        // ... (sequence of stimulus for each time step)
        #1000000;
        $finish;
    end
    final begin
        if (errors) $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", errors, errortime);
        else $display("SIMULATION PASSED");
    end
endmodule