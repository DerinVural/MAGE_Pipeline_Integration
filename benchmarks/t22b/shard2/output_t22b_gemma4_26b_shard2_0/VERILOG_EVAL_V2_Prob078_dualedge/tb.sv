`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic d,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    initial begin
        d <= 1'b0;
        @(negedge clk) wavedrom_start();
        repeat(20) @(posedge clk, negedge clk)
            d <= $random >> 2;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) begin
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
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1; 
        end
    end

    // Display first mismatch
    always @(posedge clk, negedge clk) begin
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 1) begin
                $display("FIRST MISMATCH DETECTED");
                $display("Time: %0t | clk: %b | d: %b | Expected q: %b | Got q: %b", $time, clk, d, q_ref, q_dut);
            end
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors_q > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
            $display("Hint: Output '%s' has no mismatches.", "q");
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule