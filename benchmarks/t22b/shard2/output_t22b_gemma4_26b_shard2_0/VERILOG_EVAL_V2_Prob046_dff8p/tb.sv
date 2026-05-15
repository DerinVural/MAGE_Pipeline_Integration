`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic       clk,
    output logic [7:0] d, 
    output logic       reset, 
    output logic [511:0] wavedrom_title,
    output logic       wavedrom_enable,
    input  logic       tb_match
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

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

    initial begin
        reset <= 1;
        d <= $random;
        @(negedge clk);
        @(negedge clk);
        wavedrom_start("Synchronous active-high reset");
        reset_test();
        repeat(10) @(negedge clk)
            d <= $random;
        wavedrom_stop();

        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 15);
            d <= $random;
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
    
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [7:0] d;
    logic reset;
    logic [7:0] q_ref;
    logic [7:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, d, reset, q_ref, q_dut);
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .d,
        .reset,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match)
    );

    RefModule good1 (
        .clk,
        .d,
        .reset,
        .q(q_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .d,
        .reset,
        .q(q_dut) 
    );

    bit first_mismatch_logged = 0;

    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;
            
            if (!first_mismatch_logged) begin
                $display("FIRST MISMATCH DETECTED at time %0t:", $time);
                $display("Inputs: clk=%b, reset=%b, d=%h (%b)", clk, reset, d, d);
                $display("Outputs: q_dut=%h (%b), q_ref=%h (%b)", q_dut, q_dut, q_ref, q_ref);
                first_mismatch_logged = 1;
            end
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

        if (stats1.errors_q != 0) begin
             $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        end else begin
             $display("Hint: Output '%s' has no mismatches.", "q");
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule