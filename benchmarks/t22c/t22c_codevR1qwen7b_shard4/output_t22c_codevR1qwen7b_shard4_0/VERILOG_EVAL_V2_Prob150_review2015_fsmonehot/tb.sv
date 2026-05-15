`timescale 1ps/1ps
module tb();
    reg clk = 0;
    reg d;
    reg done_counting;
    reg ack;
    reg [9:0] state;
    wire B3_next, S_next, S1_next, Count_next, Wait_next, done, counting, shift_ena;

    // Instantiate DUT
    TopModule top_module (
        .d(d),
        .done_counting(done_counting),
        .ack(ack),
        .state(state),
        .B3_next(B3_next),
        .S_next(S_next),
        .S1_next(S1_next),
        .Count_next(Count_next),
        .Wait_next(Wait_next),
        .done(done),
        .counting(counting),
        .shift_ena(shift_ena)
    );

    // Generate clock
    always #(5) clk = ~clk;

    // Stimulus
    stimulus_gen stim_gen (
        .clk(clk),
        .d(d),
        .done_counting(done_counting),
        .ack(ack),
        .state(state)
    );

    // Timeout after 100k cycles
    initial begin
        #(1000000) $display("TIMEOUT");
        $finish;
    end

    // Simulation control
    reg [$clog2(5)-1:0] error_count;
    reg [$clog2(5)-1:0] error_time_B3;
    reg [$clog2(5)-1:0] error_time_S;
    reg [$clog2(5)-1:0] error_time_S1;
    reg [$clog2(5)-1:0] error_time_Count;
    reg [$clog2(5)-1:0] error_time_Wait;
    reg [$clog2(5)-1:0] error_time_done;
    reg [$clog2(5)-1:0] error_time_counting;
    reg [$clog2(5)-1:0] error_time_shift_ena;

    reg [$clog2(5)-1:0] errors_B3_next;
    reg [$clog2(5)-1:0] errors_S_next;
    reg [$clog2(5)-1:0] errors_S1_next;
    reg [$clog2(5)-1:0] errors_Count_next;
    reg [$clog2(5)-1:0] errors_Wait_next;
    reg [$clog2(5)-1:0] errors_done;
    reg [$clog2(5)-1:0] errors_counting;
    reg [$clog2(5)-1:0] errors_shift_ena;

    initial begin
        error_count = 0;
        errors_B3_next = 0;
        errors_S_next = 0;
        errors_S1_next = 0;
        errors_Count_next = 0;
        errors_Wait_next = 0;
        errors_done = 0;
        errors_counting = 0;
        errors_shift_ena = 0;
        error_time_B3 = 0;
        error_time_S = 0;
        error_time_S1 = 0;
        error_time_Count = 0;
        error_time_Wait = 0;
        error_time_done = 0;
        error_time_counting = 0;
        error_time_shift_ena = 0;
    end

    // Monitoring mismatches on clock edges
    always @(posedge clk, negedge clk) begin
        if (error_count < 5) begin
            if (B3_next !== $past(B3_next)) begin // Example golden output check; adjust based on actual logic
                error_count += 1;
                // Track first error times
                if (error_count == 1) begin
                    error_time_B3 = $time;
                end
            end
            // Similar checks for other outputs
        end
    end

    // Final display
    integer i;
    always @(negedge clk) begin
        if ($time >= 300) begin
            if (error_count == 0) begin
                $display("SIMULATION PASSED");
            end else begin
                $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", error_count, error_time_B3);
            end
            $finish;
        end
    end
endmodule

module stimulus_gen (
    input clk,
    output reg d,
    output reg done_counting,
    output reg ack,
    output reg [9:0] state
);
    initial begin
        {d, done_counting, ack} = 0;
        state = 10'h1;
        repeat(300) @(posedge clk) begin
            {d, done_counting, ack} = $random;
            state <= 1 << ($urandom % 10);
        end
        #1 $finish;
    end
endmodule