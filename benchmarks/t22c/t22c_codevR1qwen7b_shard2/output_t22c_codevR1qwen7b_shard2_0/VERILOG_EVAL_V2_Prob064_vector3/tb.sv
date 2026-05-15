// Generated Testbench
`timescale 1ps/1ps

module tb();
    reg clk = 0;
    logic [4:0] a, b, c, d, e, f;
    logic [7:0] w_dut, w_ref;
    logic [7:0] x_dut, x_ref;
    logic [7:0] y_dut, y_ref;
    logic [7:0] z_dut, z_ref;
    logic [511:0] wavedrom_title;
    logic wavedrom_enable;

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus generation
    stimulus_gen stim_gen(
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f)
    );

    // Reference module
    RefModule golden_model(
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .w(w_ref),
        .x(x_ref),
        .y(y_ref),
        .z(z_ref)
    );

    // DUT
    TopModule dut(
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .w(w_dut),
        .x(x_dut),
        .y(y_dut),
        .z(z_dut)
    );

    // Mismatch detection
    reg [4:0] input_queue [0:9];
    reg [7:0] got_w_queue [0:9];
    reg [7:0] got_x_queue [0:9];
    reg [7:0] got_y_queue [0:9];
    reg [7:0] got_z_queue [0:9];
    reg [7:0] exp_w_queue [0:9];
    reg [7:0] exp_x_queue [0:9];
    reg [7:0] exp_y_queue [0:9];
    reg [7:0] exp_z_queue [0:9];
    integer idx = 0;
    integer mismatches = 0;
    integer first_time = -1;

    // Update queues on each clock edge
    always @(posedge clk, negedge clk) begin
        if (idx >= 9) begin
            for (int i = 0; i < 9; i++) begin
                input_queue[i] = input_queue[i+1];
                got_w_queue[i] = got_w_queue[i+1];
                got_x_queue[i] = got_x_queue[i+1];
                got_y_queue[i] = got_y_queue[i+1];
                got_z_queue[i] = got_z_queue[i+1];
                exp_w_queue[i] = exp_w_queue[i+1];
                exp_x_queue[i] = exp_x_queue[i+1];
                exp_y_queue[i] = exp_y_queue[i+1];
                exp_z_queue[i] = exp_z_queue[i+1];
            end
        end else begin
            idx = idx + 1;
        end
        input_queue[idx] = {a, b, c, d, e, f};
        got_w_queue[idx] = w_dut;
        got_x_queue[idx] = x_dut;
        got_y_queue[idx] = y_dut;
        got_z_queue[idx] = z_dut;
        exp_w_queue[idx] = w_ref;
        exp_x_queue[idx] = x_ref;
        exp_y_queue[idx] = y_ref;
        exp_z_queue[idx] = z_ref;

        if (!(w_dut === w_ref && x_dut === x_ref && y_dut === y_ref && z_dut === z_ref)) begin
            if (mismatches == 0) begin
                $display(