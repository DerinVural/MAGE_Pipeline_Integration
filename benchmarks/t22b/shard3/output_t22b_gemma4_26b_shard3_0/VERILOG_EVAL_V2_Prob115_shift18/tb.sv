`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic load,
    output logic ena,
    output logic [1:0] amount,
    output logic [63:0] data,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        load <= 1;
        ena <= 0;
        data <= 'x;
        amount <= 0;
        @(posedge clk) data <= 64'h000100;
        wavedrom_start("Shifting");
            @(posedge clk) load <= 0; ena <= 1;
                            amount <= 2;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 1;
            @(posedge clk) amount <= 1;
            @(posedge clk) amount <= 0;
            @(posedge clk) amount <= 0;
            @(posedge clk) amount <= 3;
            @(posedge clk) amount <= 3;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 2;
            @(negedge clk);
        wavedrom_stop();
        
        @(posedge clk); load <= 1; data <= 64'hx;
        @(posedge clk); load <= 1; data <= 64'h80000000_00000000;
        wavedrom_start("Arithmetic right shift");
            @(posedge clk) load <= 0; ena <= 1;
                            amount <= 2;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 2;
            @(posedge clk) amount <= 2;
            @(negedge clk);
        wavedrom_stop();

        @(posedge clk);
        @(posedge clk);
        
        repeat(4000) @(posedge clk, negedge clk) begin
            load <= !($random & 31);
            ena <= |($random & 15);
            amount <= $random;
            data <= {$random, $random};
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
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic load;
    logic ena;
    logic [1:0] amount;
    logic [63:0] data;
    logic [63:0] q_ref;
    logic [63:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, load, ena, amount, data, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .load,
        .ena,
        .amount,
        .data
    );

    // RefModule is assumed to be provided by the environment
    RefModule good1 (
        .clk,
        .load,
        .ena,
        .amount,
        .data,
        .q(q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .load,
        .ena,
        .amount,
        .data,
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
                $display("\n[MISMATCH DETECTED]");
                $display("Time: %0t", $time);
                $display("Inputs: clk=%b, load=%b, ena=%b, amount=%b, data=%h (%b)", clk, load, ena, amount, data, data);
                $display("Expected q: %h (%b)", q_ref, q_ref);
                $display("Actual q:   %h (%b)", q_dut, q_dut);
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
        if (stats1.errors_q > 0) begin
            $display("\nSIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        end else begin
            $display("\nSIMULATION PASSED");
            $display("Hint: Output 'q' has no mismatches.");
            $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        end
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule