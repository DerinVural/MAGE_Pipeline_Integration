`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_predict_taken;
        int errortime_predict_taken;
        int errors_predict_history;
        int errortime_predict_history;
        int clocks;
    } stats;
    stats stats1;
    wire tb_match, tb_mismatch;
    reg clk = 0;
    initial forever #5 clk = ~clk;

    // Declare all ports as logic and connect in stimulus_gen
    logic areset;
    logic predict_valid;
    logic [6:0] predict_pc;
    logic train_valid;
    logic train_taken;
    logic train_mispredicted;
    logic [6:0] train_history;
    logic [6:0] train_pc;
    logic predict_taken_ref;
    logic [6:0] predict_history_ref;
    logic predict_taken_dut;
    logic [6:0] predict_history_dut;

    stimulus_gen stim1(
        .clk(clk),
        .areset(areset),
        .predict_valid(predict_valid),
        .predict_pc(predict_pc),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .train_mispredicted(train_mispredicted),
        .train_history(train_history),
        .train_pc(train_pc),
        .tb_match(tb_match)
    );

    RefModule good1(
        .clk(clk),
        .areset(areset),
        .predict_valid(predict_valid),
        .predict_pc(predict_pc),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .train_mispredicted(train_mispredicted),
        .train_history(train_history),
        .train_pc(train_pc),
        .predict_taken(predict_taken_ref),
        .predict_history(predict_history_ref)
    );

    TopModule top_module1(
        .clk(clk),
        .areset(areset),
        .predict_valid(predict_valid),
        .predict_pc(predict_pc),
        .train_valid(train_valid),
        .train_taken(train_taken),
        .train_mispredicted(train_mispredicted),
        .train_history(train_history),
        .train_pc(train_pc),
        .predict_taken(predict_taken_dut),
        .predict_history(predict_history_dut)
    );

    assign tb_match = ({predict_taken_ref, predict_history_ref} === ({predict_taken_ref, predict_history_ref} ^ {predict_taken_dut, predict_history_dut} ^ {predict_taken_ref, predict_history_ref}));

    // Queue for mismatch display
    localparam MAX_QUEUE_SIZE = 8;
    reg [6:0] predict_pc_queue [0:MAX_QUEUE_SIZE-1];
    reg predict_valid_queue [0:MAX_QUEUE_SIZE-1];
    reg [6:0] predict_history_dut_queue [0:MAX_QUEUE_SIZE-1];
    reg [6:0] predict_history_ref_queue [0:MAX_QUEUE_SIZE-1];
    reg predict_taken_dut_queue [0:MAX_QUEUE_SIZE-1];
    reg predict_taken_ref_queue [0:MAX_QUEUE_SIZE-1];
    reg [6:0] train_pc_queue [0:MAX_QUEUE_SIZE-1];
    reg train_valid_queue [0:MAX_QUEUE_SIZE-1];
    reg areset_queue [0:MAX_QUEUE_SIZE-1];
    integer i;

    always @(posedge clk, negedge clk) begin
        if (stats1.errors == 0 && !tb_match) begin
            // Push to queue
            if ($size(predict_pc_queue) >= MAX_QUEUE_SIZE -1) begin
                $delete(predict_pc_queue, 0);
                $delete(predict_valid_queue, 0);
                $delete(predict_history_dut_queue, 0);
                $delete(predict_history_ref_queue, 0);
                $delete(predict_taken_dut_queue, 0);
                $delete(predict_taken_ref_queue, 0);
                $delete(train_pc_queue, 0);
                $delete(train_valid_queue, 0);
                $delete(areset_queue, 0);
            end
            predict_pc_queue = predict_pc;
            predict_valid_queue = predict_valid;
            predict_history_dut_queue = predict_history_dut;
            predict_history_ref_queue = predict_history_ref;
            predict_taken_dut_queue = predict_taken_dut;
            predict_taken_ref_queue = predict_taken_ref;
            train_pc_queue = train_pc;
            train_valid_queue = train_valid;
            areset_queue = areset;

            // Check for first mismatch
            if (!tb_match) begin
                if (stats1.errors == 0) begin
                    $display("Mismatch detected at time %t", $time);
                    $display("Last %d cycles of simulation: ", MAX_QUEUE_SIZE);
                    for (i=0; i<MAX_QUEUE_SIZE; i=i+1) begin
                        if (predict_history_ref_queue[i] === predict_history_dut_queue[i])
                            $display("Got Match at");
                        else
                            $display("Got Mismatch at");
                        $display(	"Cycle %0d, reset %b, predict_pc %h, predict_valid %b, predict_history_dut %b, predict_taken_dut %b, predict_taken_ref %b, train_pc %h, train_valid %b",
                            i, areset_queue[i], predict_pc_queue[i], predict_valid_queue[i], predict_history_dut_queue[i], predict_taken_dut_queue[i], predict_taken_ref_queue[i], train_pc_queue[i], train_valid_queue[i]);
                    end
                end
                stats1.errors = stats1.errors + 1;
                stats1.errortime = $time;
                if (i == 0) begin
                    $display("SIMULATION FAILED - 1 MISMATCH DETECTED, FIRST AT TIME %t", $time);
                    $finish;
                end
            end
        end
        stats1.clocks++;
    end

    initial begin
        areset = 1;
        predict_valid = 0;
        train_valid = 0;
        // ... (stimulus from golden testbench)
    end

    initial begin
        // Timeout after 1e6 cycles
        #1000000;
        $display("TIMEOUT");
        $finish;
    end

    // Final checks and display
    final begin
        if (stats1.errors == 0)
            $display("SIMULATION PASSED");
    end
endmodule