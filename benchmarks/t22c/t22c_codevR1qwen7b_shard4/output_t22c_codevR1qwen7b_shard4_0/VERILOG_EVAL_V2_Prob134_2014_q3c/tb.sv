module tb();
    logic clk = 0;
    logic x;
    logic [2:0] y;
    logic Y0_ref, Y0_dut;
    logic z_ref, z_dut;
    logic tb_match;
    logic [511:0] wavedrom_title;
    logic wavedrom_enable;
    logic [63:0] wavedrom_hide_after_time;
    stats stats1;
    initial forever #5 clk = ~clk;
    stimulus_gen stim1(.clk(clk), .x(x), .y(y));
    RefModule ref_mod(.clk(clk), .x(x), .y(y), .Y0(Y0_ref), .z(z_ref));
    TopModule dut(.clk(clk), .x(x), .y(y), .Y0(Y0_dut), .z(z_dut));
    assign tb_match = (Y0_ref === (Y0_ref ^ Y0_dut ^ Y0_ref)) && (z_ref === (z_ref ^ z_dut ^ z_ref));
    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            if (Y0_ref !== Y0_dut) begin
                if (stats1.errors_Y0 == 0) stats1.errortime_Y0 = $time;
                stats1.errors_Y0++;
            end
            if (z_ref !== z_dut) begin
                if (stats1.errors_z == 0) stats1.errortime_z = $time;
                stats1.errors_z++;
            end
        end
    end
    initial begin
        repeat(200) @(posedge clk);
        #1 $finish;
    end
    final begin
        if (stats1.errors_Y0 > 0 || stats1.errors_z > 0)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        else
            $display("SIMULATION PASSED");
    end
endmodule

module stimulus_gen(clk, x, y);
    input clk;
    output logic x;
    output logic [2:0] y;
    initial begin
        repeat(200) @(posedge clk);
        $finish;
    end
endmodule

struct packed stats {
    int errors;
    int errortime;
    int errors_Y0;
    int errortime_Y0;
    int errors_z;
    int errortime_z;
    int clocks;
};

stats stats1 = stats'(0);