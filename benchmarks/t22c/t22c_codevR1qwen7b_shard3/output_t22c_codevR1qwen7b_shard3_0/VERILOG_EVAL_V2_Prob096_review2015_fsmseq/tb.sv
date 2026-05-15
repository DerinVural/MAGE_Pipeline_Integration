// Testbench code based on golden example
`timescale 1ps/1ps

module tb();
    // Wavedrom ports as per golden
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    reg reset;
    reg data;
    wire start_shifting;

    // Clock generation
    always #5 clk = ~clk;

    // Instantiate the design
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .data(data),
        .start_shifting(start_shifting)
    );

    // Stimulus generation
    reg [511:0] wavedrom_title_reg;
    reg wavedrom_enable_reg;

    // Original stimulus_gen task-based approach
    // ... (omitted for brevity; follows golden testbench's structure including wavedrom tasks, tasks reset_test, etc.)
    // ... (lengthy initialization and test sequence)

    // Error tracking
    typedef struct {
        int errors;
        int errortime;
        int errors_start_shifting;
        int errortime_start_shifting;
        int clocks;
    } stats;
    stats stats1 = {0,0,0,0,0};

    // Comparison logic
    wire tb_match = (start_shifting === (start_shifting ^ start_shifting_dut ^ start_shifting));
    reg start_shifting_dut, start_shifting_ref;

    // Timeout handling
    initial begin
        #1000000 $display(