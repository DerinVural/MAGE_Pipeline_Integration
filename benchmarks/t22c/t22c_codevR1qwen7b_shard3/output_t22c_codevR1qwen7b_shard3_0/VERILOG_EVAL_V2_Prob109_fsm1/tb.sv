`timescale 1ps/1ps
module stimulus_gen(clk, in, areset, wavedrom_title, wavedrom_enable, tb_match);
    input clk;
    output logic in;
    output logic areset;
    output reg [511:0] wavedrom_title;
    output reg wavedrom_enable;
    input tb_match;
    reg reset;
    assign areset = reset;
    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin srfail = !tb_match; reset <= 0; end
        if (srfail) $display("Hint: Your reset doesn't seem to be working");
        else if (arfail && (async || !datafail)) $display("Hint: Your reset should be %s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    task wavedrom_start(input [511:0] title = ";"); endtask
    task wavedrom_stop; #1; endtask
    reg clk_in = 0;
    reg in_reg;
    reg areset_reg;
    initial begin clk_in = 0; end
    always #5 clk_in = ~clk_in;
    wire clk = clk_in;
    initial begin in = 0; areset = 0; end
    initial begin
        reset = 1;
        in_reg = 0;
        areset_reg = 0;
        @(posedge clk);
        reset <= 0;
        in_reg <= 0;
        areset_reg <= 0;
        @(posedge clk);
        in_reg <= 1;
        wavedrom_start();
        reset_test(1);
        @(posedge clk);
        in_reg <= 0;
        @(posedge clk);
        in_reg <= 0;
        @(posedge clk);
        in_reg <= 0;
        @(posedge clk);
        in_reg <= 1;
        @(posedge clk);
        in_reg <= 1;
        @(negedge clk);
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) begin
            in_reg <= $random;
            areset_reg <= !($random & 7);
        end
        #1 $finish;
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
    reg clk_trigger = 0;
    wire clk = clk_trigger;
    reg in_reg;
    reg areset_reg;
    reg out_ref;
    reg out_dut;
    reg tb_match_reg;
    reg strobe = 0;
    task wait_for_end_of_timestep(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    always @(*) wait_for_end_of_timestep();
    initial begin
        clk_trigger = 0;
        in_reg = 0;
        areset_reg = 0;
        #1000000 $finish;
    end
    always #5 clk_trigger = ~clk_trigger;
    stimulus_gen stim1(
        .clk(clk),
        .in(in_reg),
        .areset(areset_reg),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match_reg)
    );
    RefModule good1(
        .clk(clk),
        .in(in_reg),
        .areset(areset_reg),
        .out(out_ref)
    );
    TopModule top_module1(
        .clk(clk),
        .in(in_reg),
        .areset(areset_reg),
        .out(out_dut)
    );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) )) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( {out_ref} ^ {out_dut} ^ {out_ref} )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk_trigger, in_reg, areset_reg, out_ref, out_dut);
        #1;
    end
    reg [63:0] time_first = 0;
    reg [63:0] error_count = 0;
    reg mismatch = 0;
    reg [63:0] time_first_display = 0;
    reg [63:0] error_count_display = 0;
    reg mismatch_display = 0;
    always @(posedge clk, negedge clk) begin
        if (!mismatch && ({out_ref} !== {out_dut})) begin
            $display("TIME %t: Mismatch! Input: %b, Output: %b, Expected: %b", $time, in_reg, out_dut, out_ref);
            if ($bits(in_reg) <=64) $display("In (binary): %b", in_reg);
            if ($bits(out_dut) <=64) $display("DUT Out (binary): %b", out_dut);
            if ($bits(out_ref) <=64) $display("Ref Out (binary): %b", out_ref);
            time_first = $time;
            error_count = stats1.errors + stats1.errors_out;
            mismatch = 1;
        end
    end
    initial begin
        #1000000;
        $display((stats1.errors_out > 0) ? "SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d" : "SIMULATION PASSED", stats1.errors_out, stats1.errortime_out);
        $finish;
    end
endmodule