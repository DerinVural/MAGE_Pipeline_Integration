`timescale 1ps/1ps
module tb();
    typedef struct {
        int errors;
        int errortime;
        int errors_f;
        int errortime_f;
        int clocks;
    } stats;
    stats stats1;
    wire clk = 0;
    reg clk_reg = 0;
    reg [3:0] x_reg;
    reg f_dut;
    reg f_ref;
    reg tb_mismatch;
    stimulus_gen stim1 (.clk(clk_reg), .x(x_reg));
    TopModule top_mod (.x(x_reg), .f(f_dut));
    RefModule ref_mod (.x(x_reg), .f(f_ref));
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, tb, clk_reg, x_reg, f_ref, f_dut);
    end
    always @(posedge clk_reg, negedge clk_reg) begin
        stats1.clocks += 1;
        if (!tb_mismatch) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors += 1;
        end
        if (f_ref !== (f_ref ^ f_dut ^ f_ref)) begin
            if (stats1.errors_f == 0) stats1.errortime_f = $time;
            stats1.errors_f += 1;
        end
    end
    initial begin
        repeat(100) @(posedge clk_reg, negedge clk_reg);
        if (stats1.errors_f == 0) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_f, stats1.errortime_f);
        #1 $finish;
    end
endmodule
module stimulus_gen(input clk, output logic [3:0] x);
    initial begin
        repeat(100) @(posedge clk, negedge clk) x <= $random;
        #1 $finish;
    end
endmodule
module RefModule(input [3:0] x, output logic f);
    // Implement the K-map function
    // K-map logic based on the provided table
case ({x[3],x[4]})
        4'b0000: f = 1'bx;
        4'b0001: f = 0;
        4'b0011: f = 1;
        4'b0010: f = 1;
        4'b0100: f = 0;
        4'b0101: f = 1'bx;
        4'b0111: f = 1;
        4'b0110: f = 1;
        4'b1100: f = 1;
        4'b1101: f = 1;
        4'b1111: f = 1'bx;
        4'b1110: f = 0;
        4'b1000: f = 1;
        4'b1001: f = 1;
        4'b1011: f = 0;
        4'b1010: f = 1'bx;
    endcase
endmodule