// The golden testbench code as provided, adjusted to use logic ports and follow its structure
`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen(
    input clk,
    output logic reset,
    output logic [2:0] s,
    output [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin srfail = !tb_match; reset <= 0; end
        if (srfail) $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    wire [3:0][2:0] val = {3'h7, 3'h3, 3'h1, 3'h0};
    integer sval;
    initial begin
        reset <= 1;
        s <= 1;
        reset_test();
        @(posedge clk) s <= 0;
        @(posedge clk) s <= 0;
        @(negedge clk) wavedrom_start("Water rises to highest level, then down to lowest level.");
        @(posedge clk) s <= 0;
        @(posedge clk) s <= 1;
        @(posedge clk) s <= 3;
        @(posedge clk) s <= 7;
        @(posedge clk) s <= 7;
        @(posedge clk) s <= 3;
        @(posedge clk) s <= 3;
        @(posedge clk) s <= 1;
        @(posedge clk) s <= 1;
        @(posedge clk) s <= 0;
        @(posedge clk) s <= 0;
        @(negedge clk) wavedrom_stop();
        sval = 0;
        repeat(1000) begin
            @(posedge clk);
            sval = sval + (sval == 3 ? 0 : $random&1);
            s <= val[sval];
            @(negedge clk);
            sval = sval - (sval == 0 ? 0 : $random&1);
            s <= val[sval];
        end
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_fr2;
        int errortime_fr2;
        int errors_fr1;
        int errortime_fr1;
        int errors_fr0;
        int errortime_fr0;
        int errors_dfr;
        int errortime_dfr;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic [2:0] s;
    logic fr2_ref;
    logic fr2_dut;
    logic fr1_ref;
    logic fr1_dut;
    logic fr0_ref;
    logic fr0_dut;
    logic dfr_ref;
    logic dfr_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,s,fr2_ref,fr2_dut,fr1_ref,fr1_dut,fr0_ref,fr0_dut,dfr_ref,dfr_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .s(s),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .s(s),
        .fr2(fr2_ref),
        .fr1(fr1_ref),
        .fr0(fr0_ref),
        .dfr(dfr_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .s(s),
        .fr2(fr2_dut),
        .fr1(fr1_dut),
        .fr0(fr0_dut),
        .dfr(dfr_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    final begin
        if (stats1.errors_fr2) $display("Hint: Output 'fr2' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_fr2, stats1.errortime_fr2);
        else $display("Hint: Output 'fr2' has no mismatches.");
        if (stats1.errors_fr1) $display("Hint: Output 'fr1' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_fr1, stats1.errortime_fr1);
        else $display("Hint: Output 'fr1' has no mismatches.");
        if (stats1.errors_fr0) $display("Hint: Output 'fr0' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_fr0, stats1.errortime_fr0);
        else $display("Hint: Output 'fr0' has no mismatches.");
        if (stats1.errors_dfr) $display("Hint: Output 'dfr' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_dfr, stats1.errortime_dfr);
        else $display("Hint: Output 'dfr' has no mismatches.");

        $display("Hint: Total mismatched samples is %1d out of %1d samples
", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0) $display("SIMULATION PASSED");
        else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
    end

    // Timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    // Verification logic
    assign tb_match = ( { fr2_ref, fr1_ref, fr0_ref, dfr_ref } === ( { fr2_ref, fr1_ref, fr0_ref, dfr_ref } ^ { fr2_dut, fr1_dut, fr0_dut, dfr_dut } ^ { fr2_ref, fr1_ref, fr0_ref, dfr_ref } ) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (fr2_ref !== ( fr2_ref ^ fr2_dut ^ fr2_ref ))
        begin if (stats1.errors_fr2 == 0) stats1.errortime_fr2 = $time;
            stats1.errors_fr2 = stats1.errors_fr2+1'b1; end

        if (fr1_ref !== ( fr1_ref ^ fr1_dut ^ fr1_ref ))
        begin if (stats1.errors_fr1 == 0) stats1.errortime_fr1 = $time;
            stats1.errors_fr1 = stats1.errors_fr1+1'b1; end

        if (fr0_ref !== ( fr0_ref ^ fr0_dut ^ fr0_ref ))
        begin if (stats1.errors_fr0 == 0) stats1.errortime_fr0 = $time;
            stats1.errors_fr0 = stats1.errors_fr0+1'b1; end

        if (dfr_ref !== ( dfr_ref ^ dfr_dut ^ dfr_ref ))
        begin if (stats1.errors_dfr == 0) stats1.errortime_dfr = $time;
            stats1.errors_dfr = stats1.errors_dfr+1'b1; end

    end
endmodule