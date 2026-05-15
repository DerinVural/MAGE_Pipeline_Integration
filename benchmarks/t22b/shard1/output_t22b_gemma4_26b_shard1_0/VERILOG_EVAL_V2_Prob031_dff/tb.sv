`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg d,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
        wavedrom_enable <= 1;
        wavedrom_title <= title;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable <= 0;
    endtask

    always @(posedge clk, negedge clk)
        d <= $urandom;
    
    initial begin
        wavedrom_enable <= 0;
        wavedrom_title <= 0;
        @(posedge clk);
        wavedrom_start("Positive-edge triggered DFF");
        repeat(10) @(posedge clk);
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk);
        $finish;
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
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic d;
    logic q_ref;
    logic q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, d, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .d
    );

    RefModule good1 (
        .clk,
        .d,
        .q(q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .d,
        .q(q_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
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
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 0) begin
                stats1.errortime_q = $time;
                $display("FIRST MISMATCH DETECTED AT TIME %0t", $time);
                $display("Inputs: clk=%b, d=%b", clk, d);
                $display("Outputs: q_dut=%b, q_ref=%b", q_dut, q_ref);
                $display("Expected: q_ref=%b", q_ref);
            end
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule