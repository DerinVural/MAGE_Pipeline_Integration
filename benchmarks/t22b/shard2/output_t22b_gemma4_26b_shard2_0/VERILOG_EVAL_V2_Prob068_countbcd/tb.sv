`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

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
        reset_test();
        repeat(2) @(posedge clk);
        @(negedge clk);
        wavedrom_start("Counting");
            repeat(12) @(posedge clk);
        @(negedge clk);
        wavedrom_stop();
        repeat(71) @(posedge clk);
        @(negedge clk) wavedrom_start("100 rollover");
            repeat(16) @(posedge clk);
        @(negedge clk) wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk)
            reset <= !($random & 31);
        repeat(19590) @(posedge clk);
        reset <= 1'b1;
        repeat(5) @(posedge clk);
        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_ena;
        int errortime_ena;
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
    logic [3:1] ena_ref;
    logic [3:1] ena_dut;
    logic [15:0] q_ref;
    logic [15:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,ena_ref,ena_dut,q_ref,q_dut );
    end

    wire tb_match;    // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .reset 
    );

    // RefModule is assumed to be provided by the environment
    RefModule good1 (
        .clk,
        .reset,
        .ena(ena_ref),
        .q(q_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .reset,
        .ena(ena_dut),
        .q(q_dut) 
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    // Logic to display first mismatch
    initial begin
        wait(tb_mismatch);
        $display("--- FIRST MISMATCH DETECTED ---");
        $display("Time: %0t", $time);
        $display("Inputs: clk=%b, reset=%b", clk, reset);
        $display("Outputs (DUT): ena=%h (%b), q=%h (%b)", ena_dut, ena_dut, q_dut, q_dut);
        $display("Expected (REF): ena=%h (%b), q=%h (%b)", ena_ref, ena_ref, q_ref, q_ref);
        $display("-------------------------------");
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_ena) $display("Hint: Output 'ena' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_ena, stats1.errortime_ena);
        else $display("Hint: Output 'ena' has no mismatches.");
        
        if (stats1.errors_q) $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output 'q' has no mismatches.");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    assign tb_match = ( { ena_ref, q_ref } === ( { ena_ref, q_ref } ^ { ena_dut, q_dut } ^ { ena_ref, q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (ena_ref !== ( ena_ref ^ ena_dut ^ ena_ref )) begin 
            if (stats1.errors_ena == 0) stats1.errortime_ena = $time;
            stats1.errors_ena = stats1.errors_ena+1'b1; 
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q+1'b1; 
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule