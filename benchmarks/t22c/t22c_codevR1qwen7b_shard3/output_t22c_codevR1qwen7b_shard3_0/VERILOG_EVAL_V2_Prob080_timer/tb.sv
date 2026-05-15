`timescale 1ps/1ps
module stimulus_gen(input clk, output logic load, output logic [9:0] data, input tb_match);
    task wavedrom_start; endtask
    task wavedrom_stop; #1; endtask
    initial begin
        load <= 1'b0;
        wavedrom_start("Count 3, then 10 cycles");
        @(posedge clk); {data, load} <= {10'd3, 1'b1};
        @(posedge clk); {data, load} <= {10'hx, 1'b0};
        repeat(3) @(posedge clk);
        @(posedge clk); {data, load} <= {10'd10, 1'b1};
        repeat(12) @(posedge clk);
        wavedrom_stop();
        repeat(2500) @(posedge clk);
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_tc;
        int errortime_tc;
        int clocks;
    } stats;
    stats stats1 = '{errors:0, errortime:0, errors_tc:0, errortime_tc:0, clocks:0};
    logic clk = 0;
    initial forever #5 clk = ~clk;
    logic load;
    logic [9:0] data;
    logic tc_ref, tc_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1(
        .clk(clk),
        .load(load),
        .data(data),
        .tb_match(tb_match)
    );
    TopModule top_module1(
        .clk(clk),
        .load(load),
        .data(data),
        .tc(tc_dut)
    );
    RefModule ref_inst(
        .clk(clk),
        .load(load),
        .data(data),
        .tc(tc_ref)
    );
    assign tb_match = ( {tc_ref} === ( {tc_ref} ^ {tc_dut} ^ {tc_ref} ) );
    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (tc_ref !== ( tc_ref ^ tc_dut ^ tc_ref )) begin
            if (stats1.errors_tc == 0) stats1.errortime_tc = $time;
            stats1.errors_tc++;
        end
    end
    final begin
        if (stats1.errors_tc) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_tc, stats1.errortime_tc);
            $display("First Mismatch at time %0d: load=%b, data=%h, tc_dut=%b, tc_ref=%b", stats1.errortime, load, data, tc_dut, tc_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
        if (stats1.errors) $display("Total errors: %0d", stats1.errors);
    end
    initial #1000000 $display("TIMEOUT"); $finish();
endmodule

module TopModule(input logic clk, input logic load, input logic [9:0] data, output logic tc);
    logic [9:0] counter;
    initial counter = 0;
    always @(posedge clk) begin
        if (load) counter <= data;
        else if (counter != 0) counter <= counter - 1;
    end
    assign tc = (counter == 0);
endmodule

module RefModule(input logic clk, input logic load, input logic [9:0] data, output logic tc);
    reg [9:0] counter;
    always @(posedge clk) begin
        if (load) counter <= data;
        else if (counter != 0) counter <= counter - 1;
    end
    assign tc = (counter == 0);
endmodule