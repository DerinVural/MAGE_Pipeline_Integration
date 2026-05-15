`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic in,
    output logic areset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;
    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        reset <= 1;
        in <= 0;
        @(posedge clk) reset <= 0; in <= 1;
        @(posedge clk) in <= 0;
        @(posedge clk) in <= 1;
        wavedrom_start();
        @(posedge clk) in <= 0;
        @(posedge clk) in <= 1;
        @(posedge clk);
        @(negedge clk) reset <= 1;
        @(posedge clk) reset <= 0;
        @(posedge clk) in <= 1;
        @(posedge clk) in <= 1;
        @(posedge clk) in <= 0;
        @(posedge clk) in <= 1;
        @(posedge clk) in <= 0;
        @(posedge clk) in <= 1;
        @(posedge clk) in <= 1;
        @(posedge clk) in <= 1;
        @(negedge clk);
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
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
    stats stats1;
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    integer wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic in;
    logic areset;
    logic out_ref;
    logic out_dut;
    wire tb_match = ~(( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } )));
    wire tb_mismatch = !tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .areset(areset),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .clk(clk),
        .in(in),
        .areset(areset),
        .out(out_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .in(in),
        .areset(areset),
        .out(out_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    final begin
        if (stats1.errors_out) $display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out, stats1.errortime_out);
        else $display("Simulation finished at %0d ps", $time);
        $display("SIMULATION PASSED");
    end
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    initial begin #1000000; $display("TIMEOUT"); $finish(); end
endmodule