`timescale 1ps/1ps
module tb();
    // Clock and reset signals
    reg clk = 0;
    reg reset;
    reg [7:0] d;
    wire [7:0] q;
    logic tb_match;
    wire tb_mismatch = ~tb_match;
    // Error stats
    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats_t;
    stats_t stats1 = {0,0,0,0,0};
    // Instantiate DUT
    TopModule dut (
        .clk(clk),
        .reset(reset),
        .d(d),
        .q(q)
    );
    // Reference module
    reg [7:0] q_ref;
    RefModule ref_inst (
        .clk(clk),
        .d(d),
        .reset(reset),
        .q(q_ref)
    );
    // Clock generation
    initial forever #5 clk = ~clk;
    // Stimulus generation
    initial begin
        // Initialization
        reset = 1'b1;
        d = 8'h00;
        // Release reset after 10ns
        #10 reset = 1'b0;
        // Additional stimulus
        #250000;
        $finish;
    end
    // Error checking
    always @(posedge clk) begin
        stats1.clocks++;
        if (q !== q_ref) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q !== q_ref) begin
            stats1.errors_q++;
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
        end
    end
    // Timeout
    initial begin
        #1000000 $display(