// Testbench with clk and in
module tb();
    logic clk = 0;
    logic in;
    logic out_ref;
    logic out_dut;

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus generator
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            in = $random;
        end
        #1 $finish;
    end

    // DUT instantiation
    TopModule dut (
        .in(in),
        .out(out_dut)
    );

    // Reference model: out = in
    assign out_ref = in;

    // Error counting and display
    int errors = 0;
    int errortime = 0;
    int clocks = 0;

    always @(posedge clk, negedge clk) begin
        clocks++;
        if (out_ref !== out_dut) begin
            if (errors == 0) errortime = $time;
            errors++;
        end
    end

    // Simulation end and display
    initial begin
        #100000;
        $display(
            (errors > 0) ?
                "SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d" :
                "SIMULATION PASSED",
            errors, errortime
        );
        $finish;
    end
endmodule