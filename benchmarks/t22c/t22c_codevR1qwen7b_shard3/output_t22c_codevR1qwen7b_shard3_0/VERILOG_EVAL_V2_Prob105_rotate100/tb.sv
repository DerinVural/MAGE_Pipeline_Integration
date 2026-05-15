`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output reg load,
    output reg [1:0] ena,
    output reg [99:0] data
);
    always @(posedge clk) data <= {$random,$random,$random,$random};
    initial begin
        load <= 1;
        #(5000) $finish;
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
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic load;
    logic [1:0] ena;
    logic [99:0] data;
    logic [99:0] q_ref, q_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (.clk(clk), .load(load), .ena(ena), .data(data));
    RefModule good1 (.clk(clk), .load(load), .ena(ena), .data(data), .q(q_ref));
    TopModule top_module1 (.clk(clk), .load(load), .ena(ena), .data(data), .q(q_dut));
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
    integer first_mismatch_time = 0;
    integer first_mismatch_errors = 0;
    logic [99:0] data_at_mismatch, q_ref_at, q_dut_at;
    logic [1:0] ena_at;
    logic load_at;
    integer mismatch_count = 0;
    always @(negedge clk) begin
        if (!tb_match && mismatch_count == 0) begin
            first_mismatch_time = $time;
            data_at_mismatch = data;
            q_ref_at = q_ref;
            q_dut_at = q_dut;
            ena_at = ena;
            load_at = load;
            mismatch_count = 1;
        end
    end
    final begin
        if (stats1.errors_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("TIME %0d: data = %h (binary: %b), Expected q_ref: %h (binary: %b), Found q_dut: %h (binary: %b)",
                first_mismatch_time,
                data_at_mismatch, data_at_mismatch,
                q_ref_at, q_ref_at,
                q_dut_at, q_dut_at);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    initial begin
        #1000000 $finish;
    end
endmodule