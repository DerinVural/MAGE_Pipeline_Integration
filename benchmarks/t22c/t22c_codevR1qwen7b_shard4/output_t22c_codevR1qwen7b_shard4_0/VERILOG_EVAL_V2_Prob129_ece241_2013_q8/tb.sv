`timescale 1ps/1ps

module tb();
    reg clk;
    reg aresetn;
    reg x;
    wire z;
    wire z_ref;
    logic tb_match;
    logic tb_mismatch;
    reg [511:0] wavedrom_title;
    logic wavedrom_enable;
    reg tb_match_reg;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // Initialize reset
        aresetn = 0;
        x = 0;
        // Release reset after some cycles
        #20 aresetn = 1;
        // Test sequence
        #10 x = 1;
        #10 x = 0;
        #10 x = 1;
        // Add more test cases
        #100 $finish;
    end

    // Reference module
    RefModule good1(.clk(clk), .aresetn(aresetn), .x(x), .z(z_ref));

    // DUT
    TopModule dut(.clk(clk), .aresetn(aresetn), .x(x), .z(z));

    // Error counting
    always @(*) begin
        tb_match = (z === z_ref);
        tb_mismatch = ~tb_match;
    end

    // Simulation end and display
    reg [31:0] error_time;
    reg error_flag;
    reg errors;

    always @(posedge clk) begin
        if (tb_mismatch) begin
            if (errors === 0) begin
                error_time <= $time;
            end
            errors <= errors + 1;
        end
    end

    initial begin
        errors = 0;
        error_time = 0;
    end

    initial begin
        // Wait for simulation end
        #1000;
        if (errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, error_time);
        end else begin
            $display("SIMULATION PASSED");
        end
        $finish;
    end
endmodule