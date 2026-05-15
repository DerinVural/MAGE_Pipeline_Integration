`timescale 1ps/1ps

module stimulus_gen(clk);
    input clk;
    output reg shift_ena;
    output reg count_ena;
    output reg data;
    // Other ports as in original testbench, but not used here
endmodule

module tb;
    reg clk = 0;
    reg shift_ena;
    reg count_ena;
    reg data;
    wire [3:0] q_ref, q_dut;
    logic [3:0] q_golden_queue [0:9];
    logic [3:0] q_dut_queue [0:9];
    reg [3:0] expected_q [0:9];
    reg rst_queue [0:9];
    localparam MAX_QUEUE_SIZE = 9;
    reg [1:0] queue_ptr = 0;
    integer error_count = 0;
    integer first_error_time;
    reg [3:0] expected_q_reg;

    // Instantiate DUT
    TopModule top_inst (
        .clk(clk),
        .shift_ena(shift_ena),
        .count_ena(count_ena),
        .data(data),
        .q(q_dut)
    );
    // Reference module (assuming q_ref is correct behavior)
    RefModule golden_inst (
        .clk(clk),
        .shift_ena(shift_ena),
        .count_ena(count_ena),
        .data(data),
        .q(q_ref)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus generation
    initial begin
        // Stimulus setup...
        // ... original code may vary but omitted for brevity, focusing on error handling
    end

    // Error checking
    always @(posedge clk) begin
        if (q_dut !== q_ref) begin
            if (error_count == 0) begin
                first_error_time = $time;
                for (int i=0; i<queue_ptr; i++) begin
                    $display(