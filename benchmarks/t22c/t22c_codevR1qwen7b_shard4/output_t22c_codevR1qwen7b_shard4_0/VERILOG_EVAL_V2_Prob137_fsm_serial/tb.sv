`timescale 1ps/1ps

module stimulus_gen (
    input clk,
    output logic in,
    output logic reset
);
    initial begin
        reset <= 1;
        in <= 1;
        @(posedge clk);
        reset <= 0;
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(10) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(10) @(posedge clk);
        in <= 1;
        @(posedge clk);
        in <= 0;
        repeat(9) @(posedge clk);
        in <= 1;
        @(posedge clk);
        repeat(800) @(posedge clk, negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_done;
        int errortime_done;
        int clocks;
    } stats;
    stats stats1 = '0;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic in;
    logic reset;
    logic done_ref;
    logic done_dut;

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .reset(reset)
    );

    RefModule good1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .done(done_ref)
    );

    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .reset(reset),
        .done(done_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask

    reg [1:0] input_queue [$], got_output_queue [$], golden_queue [$]; reg reset_queue [$];
    localparam MAX_QUEUE_SIZE = 9;

    always @(posedge clk, negedge clk) begin
        if (input_queue.size() >= MAX_QUEUE_SIZE) begin
            input_queue.delete(0); got_output_queue.delete(0); golden_queue.delete(0); reset_queue.delete(0);
        end
        input_queue.push_back(in); got_output_queue.push_back(done_dut); golden_queue.push_back(done_ref); reset_queue.push_back(reset);

        if (got_output_queue[MAX_QUEUE_SIZE-2] !== golden_queue[MAX_QUEUE_SIZE-2]) begin
            $display(