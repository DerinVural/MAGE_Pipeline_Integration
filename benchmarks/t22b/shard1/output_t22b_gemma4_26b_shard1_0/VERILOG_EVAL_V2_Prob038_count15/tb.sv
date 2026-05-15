`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic reset,
    input  logic tb_match,
    output logic wavedrom_enable,
    output logic [511:0] wavedrom_title
);

    task wavedrom_start(input [511:0] title = "");
        wavedrom_enable = 1;
        wavedrom_title = title;
    endtask

    task wavedrom_stop;
        #1;
        wavedrom_enable = 0;
    endtask

    task reset_test(input async=0);
        bit arfail, srfail, datafail;

        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);

        @(negedge clk) begin datafail = !tb_match ; reset <= 1; end
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

    initial begin
        reset <= 1;
        wavedrom_enable <= 0;
        wavedrom_title <= 0;
        @(negedge clk);

        wavedrom_start("Reset and counting");
        reset_test();

        repeat(3) @(posedge clk);
        wavedrom_stop();

        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end
        #1 $finish;
    end

endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;

    stats stats1;

    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    reg clk=0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic [3:0] q_ref;
    logic [3:0] q_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk,
        .*,
        .reset
    );

    // RefModule is assumed to be provided by the environment
    RefModule good1 (
        .clk,
        .reset,
        .q(q_ref)
    );

    TopModule top_module1 (
        .clk,
        .reset,
        .q(q_dut)
    );

    bit mismatch_displayed = 0;

    task wait_for_end_of_timestep;
        repeat(5) begin
            static bit strobe = 0;
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            if (!mismatch_displayed) begin
                $display("FIRST MISMATCH DETECTED:");
                $display("Time: %0t", $time);
                $display("Inputs: clk=%b, reset=%b", clk, reset);
                $display("Outputs: q_dut=%h (%b), q_ref=%h (%b)", q_dut, q_dut, q_ref, q_ref);
                mismatch_displayed = 1;
            end
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_q) 
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        else 
            $display("Hint: Output 'q' has no mismatches.");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule