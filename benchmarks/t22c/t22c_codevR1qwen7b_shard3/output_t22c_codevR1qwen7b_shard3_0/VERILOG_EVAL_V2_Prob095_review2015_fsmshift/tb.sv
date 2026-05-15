`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_shift_ena;
        int errortime_shift_ena;
        int clocks;
    } stats;

    stats stats1;
    wire clk;
    reg reset;
    logic shift_ena_ref;
    logic shift_ena_dut;
    wire tb_match;
    wire tb_mismatch;

    // Clock generation
    reg clk_reg = 0;
    initial forever #5 clk_reg = ~clk_reg;
    assign clk = clk_reg;

    // Stimulus generation
    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset)
    );

    // Reference module
    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .shift_ena(shift_ena_ref)
    );

    // DUT instance
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .shift_ena(shift_ena_dut)
    );

    // Matching logic
    assign tb_match = ( {shift_ena_ref} === ( {shift_ena_ref} ^ {shift_ena_dut} ^ {shift_ena_ref} ) );
    assign tb_mismatch = ~tb_match;

    // Error counting
    always @(posedge clk) begin
        if (tb_mismatch) begin
            stats1.errors += 1;
            if (stats1.errors == 1) stats1.errortime = $time;
        end
        if (shift_ena_ref !== (shift_ena_ref ^ shift_ena_dut ^ shift_ena_ref)) begin
            stats1.errors_shift_ena += 1;
            if (stats1.errors_shift_ena == 1) stats1.errortime_shift_ena = $time;
        end
        stats1.clocks += 1;
    end

    // Timeout
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end

    // Simulation end
    final begin
        if (stats1.errors_shift_ena) begin
            $display("Simulation failed - %0d mismatches detected, first at time %0d", stats1.errors_shift_ena, stats1.errortime_shift_ena);
        end else if (stats1.errors) begin
            $display("Simulation failed - %0d mismatches detected, first at time %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("Simulation passed");
        end
    end
endmodule

module stimulus_gen (
    input clk,
    output reg reset
);
    initial begin
        repeat(100) @(negedge clk) reset <= !($random & 31);
        #1 $finish;
    end
endmodule