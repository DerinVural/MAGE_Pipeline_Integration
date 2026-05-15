`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic a
);
    // Contents from golden testbench omitted for brevity
    task wavedrom_start; endtask;
    task wavedrom_stop; endtask;
    initial begin
        a <= 1;
        // ... rest of the stimulus_gen initial block
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
    stats stats1 = 0;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic a;
    logic [2:0] q_ref, q_dut;

    RefModule good1 (.clk(clk), .a(a), .q(q_ref));
    TopModule top_module1 (.clk(clk), .a(a), .q(q_dut));
    stimulus_gen stim1 (.clk(clk), .a(a));

    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) strobe <= !strobe; @(strobe); endtask

    // Queue variables for mismatch display
    reg [3:0] input_queue [0:4]; // Assuming width of a is 1 bit
    reg [2:0] got_output_queue [0:4];
    reg [2:0] golden_queue [0:4];
    reg [0:0] reset_queue [0:4];
    localparam MAX_QUEUE_SIZE = 5;

    // Mismatch detection and queue logic
    reg [2:0] tb_match_reg;
    always @(posedge clk, negedge clk) begin
        // Track current values into queue if not full
        if (input_queue[0] !== 'x) begin // Check if queue is full
            // Shift queue elements to the left
            for (int i=0; i<MAX_QUEUE_SIZE-1; i++) begin
                input_queue[i] = input_queue[i+1];
                got_output_queue[i] = got_output_queue[i+1];
                golden_queue[i] = golden_queue[i+1];
                reset_queue[i] = reset_queue[i+1];
            end
        end
        // Push new data to the end
        input_queue[MAX_QUEUE_SIZE-1] = a;
        got_output_queue[MAX_QUEUE_SIZE-1] = q_dut;
        golden_queue[MAX_QUEUE_SIZE-1] = q_ref;
        // For reset, need to track if reset is part of interface; maybe not here.
        // Assuming no reset signal in the test

        // Check for mismatch
        if (q_dut !== q_ref) begin
            if (stats1.errors == 0) begin
                $display("Mismatch detected at time %t", $time);
                $display("Last %0d cycles of simulation:", MAX_QUEUE_SIZE);
                for (int i=0; i<MAX_QUEUE_SIZE; i++) begin
                    $display("Cycle %0d, input %b, got %h, exp %h", i, input_queue[i], got_output_queue[i], golden_queue[i]);
                end
                $display("SIMULATION FAILED - 1 MISMATCH DETECTED, FIRST AT TIME %t", $time);
                $finish;
            end
        end
    end

    // ... other parts of testbench including initial, final block, error counters
endmodule