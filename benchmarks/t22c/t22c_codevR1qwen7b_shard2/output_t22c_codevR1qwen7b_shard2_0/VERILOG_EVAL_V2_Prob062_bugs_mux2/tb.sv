`timescale 1ps/1ps
module stimulus_gen(
    input clk,
    output logic sel,
    output logic [7:0] a,
    output logic [7:0] b,
    output [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input[511:0] title = "/"); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        {a, b, sel} <= '0;
        @(negedge clk); wavedrom_start();
        repeat(3) @(posedge clk, negedge clk) {a, b, sel} <= {8'haa, 8'hbb, 1'b0};
        @(posedge clk, negedge clk) {a, b, sel} <= {8'haa, 8'hbb, 1'b1};
        @(posedge clk, negedge clk) {a, b, sel} <= {8'hff, 8'h00, 1'b0};
        @(posedge clk, negedge clk) {a, b} <= {8'hff, 8'h00}; sel <= 0;
        repeat(5) @(posedge clk, negedge clk) sel <= $urandom;
        wavedrom_stop();
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1 = '{errors:0, errortime:0, errors_out:0, errortime_out:0, clocks:0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic sel;
    logic [7:0] a, b;
    logic [7:0] out_ref, out_dut;
    wire tb_match, tb_mismatch;
    assign tb_mismatch = ~tb_match;
    stimulus_gen stim1(
        .clk(clk),
        .sel(sel),
        .a(a),
        .b(b),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1(
        .sel(sel),
        .a(a),
        .b(b),
        .out(out_ref)
    );
    TopModule top_module1(
        .sel(sel),
        .a(a),
        .b(b),
        .out(out_dut)
    );
    assign tb_match = ({out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
            $display("First Mismatch Details:");
            $display("Inputs: sel=%b, a=%h, b=%h", sel, a, b);
            $display("Outputs: out_ref=%h, out_dut=%h", out_ref, out_dut);
            $display("Expected: %h", out_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0t ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end
endmodule