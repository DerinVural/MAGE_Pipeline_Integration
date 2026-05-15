`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_both;
        int errortime_out_both;
        int errors_out_any;
        int errortime_out_any;
        int errors_out_different;
        int errortime_out_different;
        int clocks;
    } stats;
    stats stats1 = 0;

    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [3:0] in;
    logic [3:0] out_both_ref;
    logic [3:0] out_both_dut;
    logic [3:0] out_any_ref;
    logic [3:0] out_any_dut;
    logic [3:0] out_different_ref;
    logic [3:0] out_different_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, tb_mismatch, in, out_both_ref, out_both_dut, out_any_ref, out_any_dut, out_different_ref, out_different_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .tb_match(tb_match),
        .in(in),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    RefModule good1 (
        .in(in),
        .out_both(out_both_ref),
        .out_any(out_any_ref),
        .out_different(out_different_ref)
    );

    TopModule top_module1 (
        .in(in),
        .out_both(out_both_dut),
        .out_any(out_any_dut),
        .out_different(out_different_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    final begin
        if (stats1.errors_out_both)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_both, stats1.errortime_out_both);
        else if (stats1.errors_out_any)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_any, stats1.errortime_out_any);
        else if (stats1.errors_out_different)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out_different, stats1.errortime_out_different);
        else
            $display("SIMULATION PASSED");

        if (stats1.errors_out_both) begin
            $display("First mismatch in out_both at time %0d", stats1.errortime_out_both);
            $display("Input: %h%h%h%h", in[3], in[2], in[1], in[0]);
            $display("Output: out_both_ref=%h, out_both_dut=%h", out_both_ref, out_both_dut);
        end else if (stats1.errors_out_any) begin
            $display("First mismatch in out_any at time %0d", stats1.errortime_out_any);
            $display("Input: %h%h%h%h", in[3], in[2], in[1], in[0]);
            $display("Output: out_any_ref=%h, out_any_dut=%h", out_any_ref, out_any_dut);
        end else if (stats1.errors_out_different) begin
            $display("First mismatch in out_different at time %0d", stats1.errortime_out_different);
            $display("Input: %h%h%h%h", in[3], in[2], in[1], in[0]);
            $display("Output: out_different_ref=%h, out_different_dut=%h", out_different_ref, out_different_dut);
        end else if (stats1.errors) begin
            $display("First overall mismatch at time %0d", stats1.errortime);
            $display("Input: %h%h%h%h", in[3], in[2], in[1], in[0]);
            $display("Output:");
            $display("out_both_ref: %h, out_both_dut: %h", out_both_ref, out_both_dut);
            $display("out_any_ref: %h, out_any_dut: %h", out_any_ref, out_any_dut);
            $display("out_different_ref: %h, out_different_dut: %h", out_different_ref, out_different_dut);
        end
    end

    assign tb_match = ({out_both_ref, out_any_ref, out_different_ref} === ({out_both_ref, out_any_ref, out_different_ref} ^ {out_both_dut, out_any_dut, out_different_dut} ^ {out_both_ref, out_any_ref, out_different_ref}));

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_both_ref !== (out_both_ref ^ out_both_dut ^ out_both_ref)) begin
            if (stats1.errors_out_both == 0) stats1.errortime_out_both = $time;
            stats1.errors_out_both++;
        end
        if (out_any_ref !== (out_any_ref ^ out_any_dut ^ out_any_ref)) begin
            if (stats1.errors_out_any == 0) stats1.errortime_out_any = $time;
            stats1.errors_out_any++;
        end
        if (out_different_ref !== (out_different_ref ^ out_different_dut ^ out_different_ref)) begin
            if (stats1.errors_out_different == 0) stats1.errortime_out_different = $time;
            stats1.errors_out_different++;
        end
    end

    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule

module stimulus_gen (input clk, input tb_match, output logic [3:0] in, output wavedrom_title, output wavedrom_enable);
    task wavedrom_start; endtask
    task wavedrom_stop; #1; endtask

    initial begin
        in <= 4'h3;
        @(negedge clk);
        wavedrom_start();
        @(posedge clk) in <= 3;
        @(posedge clk) in <= 6;
        @(posedge clk) in <= 12;
        @(posedge clk) in <= 9;
        @(posedge clk) in <= 5;
        @(negedge clk);
        wavedrom_stop();
        in <= $random;
        repeat(100) begin
            @(negedge clk) in <= $random;
            @(posedge clk) in <= $random;
        end
        #1 $finish;
    end
endmodule