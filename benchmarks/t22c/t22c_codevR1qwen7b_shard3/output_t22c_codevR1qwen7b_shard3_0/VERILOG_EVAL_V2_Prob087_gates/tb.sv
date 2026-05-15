`timescale 1ps/1ps

module stimulus_gen(clk);
    input clk;
    output logic a, b;
    output [511:0] wavedrom_title;
    output reg wavedrom_enable;

    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask

    initial begin
        @(negedge clk) {a,b} <= 0;
        wavedrom_start();
        @(posedge clk) {a,b} <= 0;
        @(posedge clk) {a,b} <= 1;
        @(posedge clk) {a,b} <= 2;
        @(posedge clk) {a,b} <= 3;
        @(negedge clk);
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {a,b} <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_and; int errortime_out_and;
        int errors_out_or; int errortime_out_or;
        int errors_out_xor; int errortime_out_xor;
        int errors_out_nand; int errortime_out_nand;
        int errors_out_nor; int errortime_out_nor;
        int errors_out_xnor; int errortime_out_xnor;
        int errors_out_anotb; int errortime_out_anotb;
        int clocks;
    } stats;
    stats stats1 = 0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a, b;
    wire out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref;
    wire out_and_dut, out_or_dut, out_xor_dut, out_nand_dut, out_nor_dut, out_xnor_dut, out_anotb_dut;
    stimulus_gen stim1(.clk(clk), .a(a), .b(b));
    RefModule good1(
        .a(a), .b(b),
        .out_and(out_and_ref), .out_or(out_or_ref), .out_xor(out_xor_ref), .out_nand(out_nand_ref),
        .out_nor(out_nor_ref), .out_xnor(out_xnor_ref), .out_anotb(out_anotb_ref));
    TopModule top_module1(
        .a(a), .b(b),
        .out_and(out_and_dut), .out_or(out_or_dut), .out_xor(out_xor_dut), .out_nand(out_nand_dut),
        .out_nor(out_nor_dut), .out_xnor(out_xnor_dut), .out_anotb(out_anotb_dut));
    assign tb_match = ( {out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref} ===
        ( {out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref} ^ {out_and_dut, out_or_dut, out_xor_dut, out_nand_dut, out_nor_dut, out_xnor_dut, out_anotb_dut} ^ {out_and_ref, out_or_ref, out_xor_ref, out_nand_ref, out_nor_ref, out_xnor_ref, out_anotb_ref} ) );

    reg tb_match, tb_mismatch;
    always @(*) tb_mismatch = ~tb_match;

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_and_ref !== (out_and_ref ^ out_and_dut ^ out_and_ref)) begin
            if (stats1.errors_out_and == 0) stats1.errortime_out_and = $time;
            stats1.errors_out_and++;
        end
        // Similar checks for other outputs...
    end

    // Error counting for all outputs
    // Display logic
    initial begin
        // ...
        if (stats1.errors) $display(