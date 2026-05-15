// Testbench code using stimulus_gen with proper error handling and display
`timescale 1ps/1ps

module tb();
    // Declare signals
    reg clk;
    reg load;
    reg [511:0] data;
    reg [511:0] wavedrom_title;
    reg wavedrom_enable;

    // Instantiate the DUT (Device Under Test)
    stimulus_gen dut (
        .clk(clk),
        .load(load),
        .data(data),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    // Reference model or expected data
    reg [511:0] q_ref;
    reg [511:0] q_dut;
    integer errors;
    integer errortime;
    integer errors_q;
    integer errortime_q;
    integer clocks;

    // Initialize variables
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    initial begin
        // Initialize inputs
        load = 0;
        data = 0;
        wavedrom_title = 0;
        wavedrom_enable = 0;

        // Initialize error counters
        errors = 0;
        errortime = 0;
        errors_q = 0;
        errortime_q = 0;
        clocks = 0;

        // Start simulation
        // Stimulus generation
        // ... (previous stimulus code)
        // Display first mismatch
        if (load !== expected_load || data !== expected_data) begin
            $display("Time %0t: Mismatch detected - Input load=%b data=%h, Expected load=%b data=%h", $time, load, data, expected_load, expected_data);
        end
        // ... (rest of the testbench code with proper error handling and displays)
        // After simulation ends
        if (errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
        end
        $finish;
    end
endmodule