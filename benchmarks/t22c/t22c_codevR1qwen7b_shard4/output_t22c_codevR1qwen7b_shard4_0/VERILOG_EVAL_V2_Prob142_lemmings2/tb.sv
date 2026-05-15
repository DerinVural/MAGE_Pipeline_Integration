`timescale 1 ps/1 ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_walk_left;
        int errortime_walk_left;
        int errors_walk_right;
        int errortime_walk_right;
        int errors_aaah;
        int errortime_aaah;
        int clocks;
    } stats;
    stats stats1 = '0;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    // Inputs
    reg areset_r;
    reg bump_left_r;
    reg bump_right_r;
    reg ground_r;

    // Outputs
    logic walk_left_ref;
    logic walk_right_ref;
    logic aaah_ref;
    logic walk_left_dut;
    logic walk_right_dut;
    logic aaah_dut;

    // Queue variables
    localparam MAX_QUEUE_SIZE = 8;
    reg [11:0] input_queue [0:MAX_QUEUE_SIZE-1]; // Assuming 12 bits needed for inputs
    reg [11:0] got_output_queue [0:MAX_QUEUE_SIZE-1];
    reg [11:0] golden_queue [0:MAX_QUEUE_SIZE-1];
    reg reset_queue [0:MAX_QUEUE_SIZE-1];
    integer queue_ptr = 0;

    // Instantiate DUT and references
    TopModule dut (
        .clk(clk),
        .areset(areset_r),
        .bump_left(bump_left_r),
        .bump_right(bump_right_r),
        .ground(ground_r),
        .walk_left(walk_left_dut),
        .walk_right(walk_right_dut),
        .aaah(aaah_dut)
    );
    RefModule ref_mod (
        .clk(clk),
        .areset(areset_r),
        .bump_left(bump_left_r),
        .bump_right(bump_right_r),
        .ground(ground_r),
        .walk_left(walk_left_ref),
        .walk_right(walk_right_ref),
        .aaah(aaah_ref)
    );

    // Monitor and queue management
    always @(posedge clk, negedge clk) begin
        if (queue_ptr >= MAX_QUEUE_SIZE) begin
            queue_ptr = 0;
            // Shift queues
            for (int i=0; i < MAX_QUEUE_SIZE-1; i++) begin
                input_queue[i] = input_queue[i+1];
                got_output_queue[i] = got_output_queue[i+1];
                golden_queue[i] = golden_queue[i+1];
                reset_queue[i] = reset_queue[i+1];
            end
        end

        input_queue[queue_ptr] = {areset_r, bump_left_r, bump_right_r, ground_r};
        got_output_queue[queue_ptr] = {walk_left_dut, walk_right_dut, aaah_dut};
        golden_queue[queue_ptr] = {walk_left_ref, walk_right_ref, aaah_ref};
        reset_queue[queue_ptr] = areset_r;
        queue_ptr++;

        if ({walk_left_dut, walk_right_dut, aaah_dut} !== {walk_left_ref, walk_right_ref, aaah_ref}) begin
            $display("Mismatch detected at time %t", $time);
            $display("Last %d cycles of simulation:", queue_ptr);
            for (int i=0; i < queue_ptr; i++) begin
                if (got_output_queue[i] === golden_queue[i])
                    $display("Got Match at Cycle %0d", i);
                else
                    $display("Got Mismatch at Cycle %0d", i);
                $display("Time %0t: reset %b, input %b, got %b, exp %b",
                    (i == 0) ? $time - (queue_ptr*2*5) : $time - (i*2*5),
                    reset_queue[i],
                    input_queue[i],
                    got_output_queue[i],
                    golden_queue[i]
                );
            end
            $finish;
        end
    end

    // Timeout after 1e5 cycles
    initial begin #100_000_000 $display("TIMEOUT"); $finish; end

    initial begin
        // Stimulus generation
        areset_r = 1;
        bump_left_r = 0;
        bump_right_r = 0;
        ground_r = 1;
        repeat(3) @(posedge clk);
        areset_r = 0;

        // Test cases here (example)
        // ... (from golden tb) bump_left/ground scenarios
        // ... (random stimulus generation)
        #1000 $finish;
    end

    // Error counting (from golden tb)
    // ... rest as per original logic
    // Finally display result
    always @(posedge clk) begin
        if (stats1.errors == 0)
            $display("SIMULATION PASSED");
        else
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
    end
endmodule