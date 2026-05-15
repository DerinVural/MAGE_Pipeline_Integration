`timescale 1ps/1ps
module stimulus_gen(clk, d, byteena, resetn, wavedrom_title, wavedrom_enable, tb_match);
    input clk;
    output reg [15:0] d;
    output reg [1:0] byteena;
    output reg resetn;
    output reg [511:0] wavedrom_title;
    output reg wavedrom_enable;
    input tb_match;

    task wavedrom_start(input [511:0] title = "");
    endtask

    task wavedrom_stop;
        #1;
    endtask

    task reset_test(input async=0);
        reg arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) resetn <= 0;
        repeat(3) @(posedge clk);

        @(negedge clk) begin datafail = !tb_match; resetn <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            resetn <= 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask

    initial begin
        resetn = 1;
        byteena = 2'b11;
        d = 16'habcd;
        @(posedge clk);
        wavedrom_start("Synchronous active-low reset");
        reset_test(0);
        repeat(2) @(posedge clk);
        wavedrom_stop();
        @(posedge clk);

        byteena = 2'b11;
        d = $random;
        @(posedge clk);
        @(negedge clk);
        wavedrom_start("DFF with byte enables");
        repeat(10) @(posedge clk) begin
            d = $random;
            byteena = byteena + 1;
        end
        wavedrom_stop();

        repeat(400) @(posedge clk, negedge clk) begin
            byteena[0] = ($random & 3) != 0;
            byteena[1] = ($random & 3) != 0;
            d = $random;
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed { int errors; int errortime; int errors_q; int errortime_q; int clocks; } stats;
    stats stats1 = 0;
    logic clk = 0;
    initial forever #5 clk = ~clk;

    logic resetn;
    logic [1:0] byteena;
    logic [15:0] d;
    logic [15:0] q_ref, q_dut;
    wire tb_match = ( {q_ref} === ( {q_ref} ^ {q_dut} ^ {q_ref} ) );
    wire [511:0] wavedrom_title;
    logic wavedrom_enable;
    logic strobe = 0;

    task wait_for_end_of_timestep();
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask

    RefModule good1(clk, resetn, byteena, d, q_ref);
    TopModule top_module1(clk, resetn, byteena, d, q_dut);

    assign wavedrom_title = 0;
    assign wavedrom_enable = 0;

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end

    final begin
        if (stats1.errors_q) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        else $display("SIMULATION PASSED");
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule
