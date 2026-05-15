module tb();
    reg clk = 0;
    reg [2:0] y;
    reg w;
    logic Y1_ref, Y1_dut;
    stats stats1;
    typedef struct packed { int errors; int errortime; int errors_Y1; int errortime_Y1; int clocks; } stats;
    stats stats1 = 0;
    initial forever #5 clk = ~clk;
    stimulus_gen stim1(.clk(clk), .y(y), .w(w));
    RefModule ref_mod(.y(y), .w(w), .Y1(Y1_ref));
    TopModule top_mod(.y(y), .w(w), .Y1(Y1_dut));
    assign tb_match = (Y1_ref === (Y1_ref ^ Y1_dut ^ Y1_ref));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (Y1_ref !== (Y1_ref ^ Y1_dut ^ Y1_ref)) begin
            if (stats1.errors_Y1 == 0) stats1.errortime_Y1 = $time;
            stats1.errors_Y1++;
        end
    end
    initial begin repeat(100) @(posedge clk) {y, w} <= $urandom; #1 $finish; end
    initial begin if (stats1.errors_Y1) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_Y1, stats1.errortime_Y1); else $display("SIMULATION PASSED"); $display("Total samples: %0d, Mismatches: %0d", stats1.clocks, stats1.errors); $finish; end endmodule
    module stimulus_gen(clk, y, w); input clk; output reg [2:0] y; output reg w; initial repeat(100) @(posedge clk) {y, w} <= $random; #1 $finish; endmodule
    module RefModule(y, w, Y1); input [2:0] y; input w; output Y1; assign Y1 = y[1]; endmodule