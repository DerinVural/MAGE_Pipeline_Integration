`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic x, z_ref, z_dut;
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .x(x),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    TopModule top_module1 (
        .clk(clk),
        .x(x),
        .z(z_dut)
    );
    RefModule good1 (
        .clk(clk),
        .x(x),
        .z(z_ref)
    );
    assign tb_match = ({z_ref} === ({z_ref} ^ {z_dut} ^ {z_ref}));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (z_ref !== (z_ref ^ z_dut ^ z_ref)) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z++;
        end
    end
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, tb, clk, x, z_ref, z_dut);
    end
    final begin
        if (stats1.errors_z) $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output 'z' has no mismatches.");
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        else $display("SIMULATION PASSED");
    end
    initial #1e6 $finish;
endmodule

module stimulus_gen (
    input clk,
    output logic x,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        x <= 0;
        @(negedge clk) wavedrom_start();
        @(posedge clk) x <= 0;
        repeat(4) @(posedge clk) x <= 1;
        @(negedge clk) wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) x <= $random;
        $finish;
    end
endmodule

module RefModule(clk, x, z);
    input clk;
    input x;
    output z;
    logic q0, q1, q2;
    always @(posedge clk) begin
        q0 <= x ^ q0;
    end
    always @(posedge clk) begin
        q1 <= x & ~q1;
    end
    always @(posedge clk) begin
        q2 <= x | ~q2;
    end
    assign z = ~(q0 | q1 | q2);
    initial begin
        q0 = 0;
        q1 = 0;
        q2 = 0;
    end
endmodule