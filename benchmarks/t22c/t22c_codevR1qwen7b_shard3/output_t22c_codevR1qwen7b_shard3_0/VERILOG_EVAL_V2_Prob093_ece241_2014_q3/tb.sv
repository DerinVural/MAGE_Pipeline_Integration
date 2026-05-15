`timescale 1ps/1ps

module stimulus_gen (
    input clk,
    output logic c,
    output logic d,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);
    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        {c, d} <= 2'b0;
        @(negedge clk) wavedrom_start();
        @(posedge clk) {c, d} <= 2'b00;
        @(posedge clk) {c, d} <= 2'b01;
        @(posedge clk) {c, d} <= 2'b11;
        @(posedge clk) {c, d} <= 2'b10;
        @(negedge clk) wavedrom_stop();
        repeat(50) @(posedge clk, negedge clk) {c,d} <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_mux_in;
        int errortime_mux_in;
        int clocks;
    } stats;
    stats stats1;
    logic clk = 0;
    initial forever #5 clk = ~clk;
    logic c, d;
    logic [3:0] mux_in_ref, mux_in_dut;
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .c(c),
        .d(d),
        .wavedrom_title(),
        .wavedrom_enable()
    );
    RefModule good1 (.c(c), .d(d), .mux_in(mux_in_ref));
    TopModule top_module1 (.c(c), .d(d), .mux_in(mux_in_dut));
    bit strobe = 0;
    task wait_for_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    reg [3:0] input_queue [0:9];
    reg [3:0] got_queue [0:9];
    reg [3:0] golden_queue [0:9];
    reg rst_queue [0:9];
    localparam MAX_QUEUE_SIZE = 10;
    integer i;
    always @(posedge clk, negedge clk) begin
        wait_for_timestep();
        if (input_queue[0] !== 'bx) begin
            if (got_queue[0] !== golden_queue[0]) begin
                $display("SIMULATION FAILED - 1 MISMATCHES DETECTED, FIRST AT TIME %0d", $time);
                $display("Cycle 0, reset %b, input %h, got output %h, exp output %h", 0, input_queue[0], got_queue[0], golden_queue[0]);
                $finish;
            end
        end
        if ($time >= 1000000) begin $display("TIMEOUT"); $finish; end
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (mux_in_ref !== (mux_in_ref ^ mux_in_dut ^ mux_in_ref)) begin
            if (stats1.errors_mux_in == 0) stats1.errortime_mux_in = $time;
            stats1.errors_mux_in++;
        end
        // Shift queues
        for (i = 0; i < MAX_QUEUE_SIZE-1; i++) begin
            input_queue[i] = input_queue[i+1];
            got_queue[i] = got_queue[i+1];
            golden_queue[i] = golden_queue[i+1];
            rst_queue[i] = rst_queue[i+1];
        end
        input_queue[MAX_QUEUE_SIZE-1] = {c, d};
        got_queue[MAX_QUEUE_SIZE-1] = mux_in_dut;
        golden_queue[MAX_QUEUE_SIZE-1] = mux_in_ref;
        rst_queue[MAX_QUEUE_SIZE-1] = 0;
    end
    final begin
        if (stats1.errors_mux_in) $display("Hint: Output 'mux_in' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_mux_in, stats1.errortime_mux_in);
        else $display("SIMULATION PASSED");
        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
    end
endmodule