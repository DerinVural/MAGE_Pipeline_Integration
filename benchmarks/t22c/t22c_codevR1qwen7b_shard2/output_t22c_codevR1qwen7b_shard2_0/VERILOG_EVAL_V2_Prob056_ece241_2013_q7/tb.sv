`timescale 1ps/1ps

module stimulus_gen (
    input clk,
    output logic j,
    output logic k,
    output [511:0] wavedrom_title,
    output wavedrom_enable
);
    // Content as per original golden testbench
    task wavedrom_start; endtask
    task wavedrom_stop; endtask
    initial begin
        {j, k} <= 1;
        @(negedge clk) wavedrom_start();
        // ... other assignments
    end
endmodule

module tb();
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic j, k, Q_dut, Q_ref;
    wire tb_match = (Q_ref === Q_dut);
    TopModule top_module1 (.clk(clk), .j(j), .k(k), .Q(Q_dut));
    RefModule good1 (.clk(clk), .j(j), .k(k), .Q(Q_ref));
    // Queue variables
    localparam MAX_QUEUE_SIZE = 4;
    logic [0:0] j_queue [MAX_QUEUE_SIZE-1:0];
    logic [0:0] k_queue [MAX_QUEUE_SIZE-1:0];
    logic [0:0] Q_dut_queue [MAX_QUEUE_SIZE-1:0];
    logic [0:0] Q_ref_queue [MAX_QUEUE_SIZE-1:0];
    logic [31:0] time_queue [MAX_QUEUE_SIZE-1:0];
    integer queue_ptr = 0;
    integer errors = 0, err_time, clocks = 0;
    always @(posedge clk, negedge clk) begin
        clocks++;
        if (!tb_match) begin
            if (!errors) err_time = $time;
            errors++;
            if (queue_ptr < MAX_QUEUE_SIZE) begin
                j_queue[queue_ptr] = j;
                k_queue[queue_ptr] = k;
                Q_dut_queue[queue_ptr] = Q_dut;
                Q_ref_queue[queue_ptr] = Q_ref;
                time_queue[queue_ptr] = $time;
                queue_ptr++;
            end
        end
    end
    initial begin
        #1000000;
        if (!errors) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, err_time);
        $finish;
    end
endmodule