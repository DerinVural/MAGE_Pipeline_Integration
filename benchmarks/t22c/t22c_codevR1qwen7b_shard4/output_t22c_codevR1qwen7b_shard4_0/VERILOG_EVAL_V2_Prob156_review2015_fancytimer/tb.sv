module stimulus_gen (
    input wire clk,
    output reg reset,
    output reg data,
    output reg ack,
    input wire tb_match,
    input wire counting_dut
);
    bit failed = 0;
    int counting_cycles = 0;

    always @(posedge clk)
        if (!tb_match)
            failed <= 1;

    always @(posedge clk)
        if (counting_dut)
            counting_cycles++;

    initial begin
        @(posedge clk);
        failed <= 0;
        reset <= 1;
        data <= 0;
        ack <= 1'bx;
        @(posedge clk) begin
            data <= 1;
            reset <= 0;
        end
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 0;
        @(posedge clk) data <= 1;
        @(posedge clk);
        data <= 1'bx;
        repeat(2000) @(posedge clk);
        ack <= 1'b0;
        repeat(3) @(posedge clk);
        ack <= 1'b1;
        @(posedge clk);
        ack <= 1'b0;
        data <= 1'b1;
        if (counting_cycles != 2000)
            $display("Hint: The first test case should count for 2000 cycles. Your circuit counted %0d", counting_cycles);
        counting_cycles <= 0;
        @(posedge clk);
        ack <= 1'bx;
        data <= 1'b1;
        @(posedge clk);
        data <= 1'b0;
        @(posedge clk);
        data <= 1'b1;
        @(posedge clk); data <= 1'b1;
        @(posedge clk); data <= 1'b1;
        @(posedge clk); data <= 1'b1;
        @(posedge clk); data <= 1'b0;
        repeat(14800) @(posedge clk);
        ack <= 1'b0;
        repeat(400) @(posedge clk);
        if (counting_cycles != 15000)
            $display("Hint: The second test case should count for 15000 cycles. Your circuit counted %0d", counting_cycles);
        counting_cycles <= 0;
        if (failed)
            $display("Hint: Your FSM didn't pass the sample timing diagram posted with the problem statement. Perhaps try debugging that?" );
        repeat(1000) @(posedge clk, negedge clk) begin
            reset <= !($random & 8191);
            data <= $random;
            ack <= !($random & 31);
        end
        repeat(100000) @(posedge clk) begin
            reset <= !($random & 8191);
            data <= $random;
            ack <= !($random & 31);
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_count;
        int errortime_count;
        int errors_counting;
        int errortime_counting;
        int errors_done;
        int errortime_done;
        int clocks;
    } stats;
    stats stats1 = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic reset;
    logic data;
    logic ack;
    logic [3:0] count_ref;
    logic [3:0] count_dut;
    logic counting_ref;
    logic counting_dut;
    logic done_ref;
    logic done_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .data(data),
        .ack(ack),
        .tb_match(tb_match),
        .counting_dut(counting_dut)
    );
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .data(data),
        .ack(ack),
        .count(count_dut),
        .counting(counting_dut),
        .done(done_dut)
    );
    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .data(data),
        .ack(ack),
        .count(count_ref),
        .counting(counting_ref),
        .done(done_ref)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (count_ref !== (count_ref ^ count_dut ^ count_ref)) begin
            if (stats1.errors_count == 0) stats1.errortime_count = $time;
            stats1.errors_count++;
        end
        if (counting_ref !== (counting_ref ^ counting_dut ^ counting_ref)) begin
            if (stats1.errors_counting == 0) stats1.errortime_counting = $time;
            stats1.errors_counting++;
        end
        if (done_ref !== (done_ref ^ done_dut ^ done_ref)) begin
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done++;
        end
    end
    initial begin
        if (stats1.errors_count) $display("Hint: Output 'count' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_count, stats1.errortime_count);
        else $display("Hint: Output 'count' has no mismatches.");
        if (stats1.errors_counting) $display("Hint: Output 'counting' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_counting, stats1.errortime_counting);
        else $display("Hint: Output 'counting' has no mismatches.");
        if (stats1.errors_done) $display("Hint: Output 'done' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_done, stats1.errortime_done);
        else $display("Hint: Output 'done' has no mismatches.");
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) begin
            if (stats1.errortime) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED", stats1.errors);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule