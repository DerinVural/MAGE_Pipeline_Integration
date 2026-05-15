`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Reference Module implementation to allow testbench to run
// In some environments, this might be provided externally.
module RefModule (
    input  logic clk,
    input  logic reset,
    output logic [4:0] q
);
    logic [4:0] q_reg;
    always_ff @(posedge clk) begin
        if (reset) begin
            q_reg <= 5'b00001;
        end else begin
            // Galois LFSR: shift right. Taps at 5 and 3 (1-indexed) -> 4 and 2 (0-indexed).
            // Mask 5'b01010 corresponds to indices 4 and 2.
            q_reg <= {1'b0, q_reg[4:1]} ^ (q_reg[0] ? 5'b01010 : 5'b00000);
        end
    end
    assign q = q_reg;
endmodule

module stimulus_gen (
    input clk,
    output reg reset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);

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

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        reset <= 1;
        @(negedge clk);
        wavedrom_start();
            reset_test();
            repeat(8) @(posedge clk);
        @(negedge clk);
        wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end
        @(posedge clk) reset <= 1'b0;
        repeat(2000) @(posedge clk);
        reset <= 1'b1;
        repeat(5) @(posedge clk);
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
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic reset;
    logic [4:0] q_ref;
    logic [4:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, q_ref, q_dut);
    end

    wire tb_match; // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .reset
    );

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

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    final begin
        if (stats1.errors_q > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
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
                $display("Mismatch detected at time %0t:", $time);
                $display("  Inputs: clk=%b, reset=%b", clk, reset);
                $display("  Expected q: %h (bin: %b)", q_ref, q_ref);
                $display("  Actual q:   %h (bin: %b)", q_dut, q_dut);
            end
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end
endmodule