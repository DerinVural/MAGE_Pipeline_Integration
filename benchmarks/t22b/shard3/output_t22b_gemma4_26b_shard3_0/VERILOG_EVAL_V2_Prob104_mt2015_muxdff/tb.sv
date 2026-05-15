`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic L,
    output logic r_in,
    output logic q_in
);

    always @(posedge clk, negedge clk)
        {L, r_in, q_in} <= $random % 8;
    
    initial begin
        repeat(100) @(posedge clk);
        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_Q;
        int errortime_Q;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic L;
    logic q_in;
    logic r_in;
    logic Q_ref;
    logic Q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, L, q_in, r_in, Q_ref, Q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .L,
        .q_in,
        .r_in
    );

    RefModule good1 (
        .clk,
        .L,
        .q_in,
        .r_in,
        .Q(Q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .L,
        .q_in,
        .r_in,
        .Q(Q_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { Q_ref } === ( { Q_ref } ^ { Q_dut } ^ { Q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("FIRST MISMATCH DETECTED at time %0t:", $time);
                $display("Inputs: L=%b, q_in=%b, r_in=%b", L, q_in, r_in);
                $display("Output (DUT): Q_dut=%b (HEX: %h, BIN: %b)", Q_dut, Q_dut, Q_dut);
                $display("Expected (REF): Q_ref=%b (HEX: %h, BIN: %b)", Q_ref, Q_ref, Q_ref);
            end
            stats1.errors++;
        end

        if (Q_ref !== ( Q_ref ^ Q_dut ^ Q_ref )) begin 
            if (stats1.errors_Q == 0) stats1.errortime_Q = $time;
            stats1.errors_Q = stats1.errors_Q + 1'b1;
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_Q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Q", stats1.errors_Q, stats1.errortime_Q);
        else $display("Hint: Output '%s' has no mismatches.", "Q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule