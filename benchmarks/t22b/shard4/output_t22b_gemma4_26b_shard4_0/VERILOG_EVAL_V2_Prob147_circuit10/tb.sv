`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    initial begin
        a <= 1;
        b <= 0;
        wavedrom_enable <= 0;
        @(negedge clk) {a,b} <= 0;
        @(negedge clk) wavedrom_start("Unknown circuit");
            wavedrom_enable <= 1;
            repeat(3) @(posedge clk);
            {a,b} <= 1;
            @(posedge clk) {a,b} <= 2;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 2;
            @(posedge clk) {a,b} <= 1;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 0;
            @(negedge clk);
        wavedrom_stop();
        wavedrom_enable <= 0;

        repeat(200) @(posedge clk, negedge clk)
            {a,b} <= $urandom_range(0, 3);
        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int errors_state;
        int errortime_state;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic a;
    logic b;
    logic q_ref;
    logic q_dut;
    logic state_ref;
    logic state_dut;

    // Queues for mismatch display
    logic [1:0] q_a_hist [$];
    logic [1:0] q_b_hist [$];
    logic q_dut_hist [$];
    logic q_ref_hist [$];
    logic state_dut_hist [$];
    logic state_ref_hist [$];
    localparam MAX_QUEUE_SIZE = 10;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, a, b, q_ref, q_dut, state_ref, state_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk,
        .a,
        .b,
        .wavedrom_title,
        .wavedrom_enable
    );

    RefModule good1 (
        .clk,
        .a,
        .b,
        .q(q_ref),
        .state(state_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .a,
        .b,
        .q(q_dut),
        .state(state_dut)
    );

    assign tb_match = ( { q_ref, state_ref } === ( { q_ref, state_ref } ^ { q_dut, state_dut } ^ { q_ref, state_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Queue Management
        if (q_a_hist.size() >= MAX_QUEUE_SIZE) begin
            q_a_hist.delete(0);
            q_b_hist.delete(0);
            q_dut_hist.delete(0);
            q_ref_hist.delete(0);
            state_dut_hist.delete(0);
            state_ref_hist.delete(0);
        end
        q_a_hist.push_back(a);
        q_b_hist.push_back(b);
        q_dut_hist.push_back(q_dut);
        q_ref_hist.push_back(q_ref);
        state_dut_hist.push_back(state_dut);
        state_ref_hist.push_back(state_ref);

        stats1.clocks++;

        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Display Queue on first mismatch
            if (stats1.errors == 1) begin
                $display("Mismatch detected at time %t", $time);
                $display("First mismatch queue contents:");
                for (int i = 0; i < q_a_hist.size(); i++) begin
                    $display("Time offset: %0d | a=%b b=%b | q_dut=%b q_ref=%b | state_dut=%b state_ref=%b", 
                             i, q_a_hist[i], q_b_hist[i], q_dut_hist[i], q_ref_hist[i], state_dut_hist[i], state_ref_hist[i]);
                end
            end
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1;
        end

        if (state_ref !== ( state_ref ^ state_dut ^ state_ref )) begin 
            if (stats1.errors_state == 0) stats1.errortime_state = $time;
            stats1.errors_state = stats1.errors_state + 1;
        end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        if (stats1.errors_state) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "state", stats1.errors_state, stats1.errortime_state);
        else $display("Hint: Output '%s' has no mismatches.", "state");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule