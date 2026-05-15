`timescale 1ps/1ps

module stimulus_gen (input clk, output reg reset);
    initial begin
        repeat(400) @(posedge clk, negedge clk) reset <= !($random & 31);
        @(posedge clk) reset <= 0;
        repeat(200000) @(posedge clk);
        reset <= 1;
        repeat(5) @(posedge clk);
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    stats stats1;
    logic clk = 0;
    initial forever #5 clk = ~clk;
    logic reset;
    logic [31:0] q_ref, q_dut;
    wire tb_match, tb_mismatch;
    reg [31:0] input_queue [0:4];
    reg [31:0] got_output_queue [0:4];
    reg [31:0] golden_queue [0:4];
    reg reset_queue [0:4];
    localparam MAX_QUEUE_SIZE =5;
    stimulus_gen stim1 (.clk(clk), .reset(reset));
    RefModule good1 (.clk(clk), .reset(reset), .q(q_ref));
    TopModule top_module1 (.clk(clk), .reset(reset), .q(q_dut));
    assign tb_match = (q_ref === (q_ref ^ q_dut ^ q_ref));
    assign tb_mismatch = ~tb_match;
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors ==0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q ==0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
        if (stats1.errors_q >=1) begin
            if (input_queue[0]===0) begin
                $display(