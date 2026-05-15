`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic reset,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input  logic tb_match
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
        wavedrom_start("Synchronous reset");
        reset_test();
        repeat(5) @(posedge clk);
        wavedrom_stop();

        reset <= 0;
        
        repeat(989) @(negedge clk);
        wavedrom_start("Wrap around behaviour");
        repeat(14)@(posedge clk);
        wavedrom_stop();
        
        repeat(2000) @(posedge clk, negedge clk) begin
            reset <= !($random & 127);
        end
        reset <= 0;
        repeat(2000) @(posedge clk);

        #1 $finish;
    end
endmodule

module RefModule (
    input  logic clk,
    input  logic reset,
    output logic [9:0] q
);
    logic [9:0] count;
    always_ff @(posedge clk) begin
        if (reset) count <= 10'd0;
        else if (count >= 10'd999) count <= 10'd0;
        else count <= count + 1'b1;
    end
    assign q = count;
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
    initial forever #5 clk = ~clk;

    logic reset;
    logic [9:0] q_ref;
    logic [9:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .reset,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match)
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
                $display("Mismatch Detected at %0t ps!", $time);
                $display("Inputs: clk=%b, reset=%b", clk, reset);
                $display("Outputs: q_dut=%h (%b), q_ref=%h (%b), expected: %h (%b)", 
                         q_dut, q_dut, q_ref, q_ref, q_ref, q_ref);
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
        if (stats1.errors_q > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule