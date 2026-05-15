`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [7:0] in,
    output logic reset
);

    initial begin
        in <= 8'b0;
        reset <= 1'b0;
        repeat(200) @(negedge clk) begin
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
        int errors_done;
        int errortime_done;
        int clocks;
    } stats;
    
    stats stats1;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic [7:0] in;
    logic reset;
    logic done_ref;
    logic done_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, clk, in, reset, done_ref, done_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk,
        .*,
        .in,
        .reset
    );

    // Note: RefModule is assumed to be provided by the test environment 
    // as per the error log provided in the prompt.
    RefModule good1 (
        .clk,
        .in,
        .reset,
        .done(done_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .in,
        .reset,
        .done(done_dut) 
    );

    bit first_mismatch_reported = 0;

    // Verification logic matching the golden testbench pattern
    assign tb_match = ( { done_ref } === ( { done_ref } ^ { done_dut } ^ { done_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            if (!first_mismatch_reported) begin
                $display("FIRST MISMATCH DETECTED at time %0t:", $time);
                $display("in: %h (%b)", in, in);
                $display("reset: %b", reset);
                $display("done_dut: %b", done_dut);
                $display("done_ref (Expected): %b", done_ref);
                first_mismatch_reported = 1;
            end
        end

        if (done_ref !== ( done_ref ^ done_dut ^ done_ref )) begin 
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done = stats1.errors_done + 1'b1;
        end
    end

    initial begin
      #1000000;
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end

        if (stats1.errors_done) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else 
            $display("Hint: Output '%s' has no mismatches.", "done");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule