module stimulus_gen (
    input clk,
    output reg load,
    output reg [511:0] data,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);

task wavedrom_start(input [511:0] title = ""); endtask

task wavedrom_stop; #1; endtask

initial begin
    data <= 0;
    data[0] <= 1'b1;
    load <= 1;
    @(posedge clk); wavedrom_start("Load q[511:0] = 1: See Hint");
    @(posedge clk);
    @(posedge clk);
    load <= 0;
    repeat(10) @(posedge clk);
    wavedrom_stop();

    data <= 0;
    data[256] <= 1'b1;
    load <= 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    load <= 0;
    repeat(1000) @(posedge clk);
    data <= 512'h4df;
    load <= 1;
    @(posedge clk);
    load <= 0;
    repeat(1000) @(posedge clk);
    data <= $random;
    load <= 1;
    @(posedge clk);
    load <= 0;
    repeat(1000) @(posedge clk);

    data <= 0;
    load <= 1;
    repeat(20) @(posedge clk);
    @(posedge clk) data <= 2;
    @(posedge clk) data <= 4;
    @(posedge clk) begin data <= 9; load <= 0; end
    @(posedge clk) data <= 12;
    repeat(100) @(posedge clk);

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
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    reg load;
    reg [511:0] data;
    reg [511:0] q_ref;
    reg [511:0] q_dut;
    wire tb_match, tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .load(load),
        .data(data),
        .wavedrom_title(),
        .wavedrom_enable()
    );
    RefModule good1 (
        .clk(clk),
        .load(load),
        .data(data),
        .q(q_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .load(load),
        .data(data),
        .q(q_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep();
        repeat(5) begin
            strobe = ~strobe;
            @(posedge clk);
        end
    endtask

    final begin
        if (stats1.errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        else $display("SIMULATION PASSED");
        $display("Total mismatched samples is %0d out of %0d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    // Timeout after 100K cycles
    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish;
    end

    // Verification logic
    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end
endmodule