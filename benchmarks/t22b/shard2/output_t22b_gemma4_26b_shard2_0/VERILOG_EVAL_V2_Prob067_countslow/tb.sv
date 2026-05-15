`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Reference Model to make the testbench functional
module RefModule (
    input logic clk,
    input logic slowena,
    input logic reset,
    output logic [3:0] q
);
    always_ff @(posedge clk) begin
        if (reset) begin
            q <= 4'd0;
        end else if (slowena) begin
            if (q == 4'd9) q <= 4'd0;
            else q <= q + 1'b1;
        end
    end
endmodule

module stimulus_gen (
    input logic clk,
    output logic slowena,
    output logic reset,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input logic tb_match
);

    task reset_test(input bit async=0);
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

    task wavedrom_start(input [511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask
    
    task wavedrom_stop;
        wavedrom_enable = 0;
        #1;
    endtask    

    reg hint1;
    initial begin
        reset <= 1;
        slowena <= 1;
        wavedrom_start("Synchronous reset and counting.");
        reset_test();
        repeat(12) @(posedge clk);
        wavedrom_stop();
        @(posedge clk);

        reset <= 1;
        @(posedge clk);
        reset <= 0;
        repeat(9) @(posedge clk);
        slowena <= 0;
        @(negedge clk) hint1 = tb_match;
        repeat(3) @(posedge clk);
        if (hint1 && !tb_match) begin
            $display ("Hint: What is supposed to happen when the counter is 9 and not enabled?");
        end
        slowena <= 1;
        reset <= 1;
        @(posedge clk);
        reset <= 0;

        wavedrom_start("Enable/disable");
        repeat(15) @(posedge clk) slowena <= !($random & 1);
        wavedrom_stop();
        @(posedge clk);

        repeat(400) @(posedge clk, negedge clk) begin
            slowena <= !($random&3);
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

    logic slowena;
    logic reset;
    logic [3:0] q_ref;
    logic [3:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,slowena,reset,q_ref,q_dut );
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .slowena,
        .reset,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match) 
    );

    RefModule good1 (
        .clk,
        .slowena,
        .reset,
        .q(q_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .slowena,
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
                $display("FIRST MISMATCH DETECTED AT TIME %0t:", $time);
                $display("Inputs: clk=%b, reset=%b, slowena=%b", clk, reset, slowena);
                $display("Expected q: %h (bin: %b)", q_ref, q_ref);
                $display("Actual q:   %h (bin: %b)", q_dut, q_dut);
            end
            stats1.errors_q = stats1.errors_q + 1'b1; 
        end
    end

    initial begin
      #1000000;
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule