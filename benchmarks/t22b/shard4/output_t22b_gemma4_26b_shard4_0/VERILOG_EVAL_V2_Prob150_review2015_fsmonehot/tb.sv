`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg d, done_counting, ack,
    output reg [9:0] state,
    input tb_match
);

    initial begin
        {d, done_counting, ack} <= 3'h0;
        state <= 10'h0;
        
        repeat(300) @(posedge clk, negedge clk) begin
            {d, done_counting, ack} = $random;
            state <= 1 << ($unsigned($random) % 10);
        end

        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_B3_next;
        int errortime_B3_next;
        int errors_S_next;
        int errortime_S_next;
        int errors_S1_next;
        int errortime_S1_next;
        int errors_Count_next;
        int errortime_Count_next;
        int errors_Wait_next;
        int errortime_Wait_next;
        int errors_done;
        int errortime_done;
        int errors_counting;
        int errortime_counting;
        int errors_shift_ena;
        int errortime_shift_ena;

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
    logic done_counting;
    logic ack;
    logic [9:0] state;
    logic B3_next_ref;
    logic B3_next_dut;
    logic S_next_ref;
    logic S_next_dut;
    logic S1_next_ref;
    logic S1_next_dut;
    logic Count_next_ref;
    logic Count_next_dut;
    logic Wait_next_ref;
    logic Wait_next_dut;
    logic done_ref;
    logic done_dut;
    logic counting_ref;
    logic counting_dut;
    logic shift_ena_ref;
    logic shift_ena_dut;

    // Queues for mismatch display
    logic d_q [$];
    logic done_counting_q [$];
    logic ack_q [$];
    logic [9:0] state_q [$];
    logic B3_next_ref_q [$];
    logic B3_next_dut_q [$];
    logic S_next_ref_q [$];
    logic S_next_dut_q [$];
    logic S1_next_ref_q [$];
    logic S1_next_dut_q [$];
    logic Count_next_ref_q [$];
    logic Count_next_dut_q [$];
    logic Wait_next_ref_q [$];
    logic Wait_next_dut_q [$];
    logic done_ref_q [$];
    logic done_dut_q [$];
    logic counting_ref_q [$];
    logic counting_dut_q [$];
    logic shift_ena_ref_q [$];
    logic shift_ena_dut_q [$];
    
    localparam MAX_QUEUE_SIZE = 10;
    bit first_mismatch_displayed = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,d,done_counting,ack,state,B3_next_ref,B3_next_dut,S_next_ref,S_next_dut,S1_next_ref,S1_next_dut,Count_next_ref,Count_next_dut,Wait_next_ref,Wait_next_dut,done_ref,done_dut,counting_ref,counting_dut,shift_ena_ref,shift_ena_dut );
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .d,
        .done_counting,
        .ack,
        .state );

    // Note: RefModule must be defined in the environment
    RefModule good1 (
        .d,
        .done_counting,
        .ack,
        .state,
        .B3_next(B3_next_ref),
        .S_next(S_next_ref),
        .S1_next(S1_next_ref),
        .Count_next(Count_next_ref),
        .Wait_next(Wait_next_ref),
        .done(done_ref),
        .counting(counting_ref),
        .shift_ena(shift_ena_ref) );
        
    TopModule top_module1 (
        .d,
        .done_counting,
        .ack,
        .state,
        .B3_next(B3_next_dut),
        .S_next(S_next_dut),
        .S1_next(S1_next_dut),
        .Count_next(Count_next_dut),
        .Wait_next(Wait_next_dut),
        .done(done_dut),
        .counting(counting_dut),
        .shift_ena(shift_ena_dut) );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  
            @(strobe);
        end
    endtask    

    assign tb_match = ( { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } === ( { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } ^ { B3_next_dut, S_next_dut, S1_next_dut, Count_next_dut, Wait_next_dut, done_dut, counting_dut, shift_ena_dut } ^ { B3_next_ref, S_next_ref, S1_next_ref, Count_next_ref, Wait_next_ref, done_ref, counting_ref, shift_ena_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Maintain Queues
        if (d_q.size() >= MAX_QUEUE_SIZE - 1) begin
            d_q.delete(0); done_counting_q.delete(0); ack_q.delete(0); state_q.delete(0);
            B3_next_ref_q.delete(0); B3_next_dut_q.delete(0); S_next_ref_q.delete(0); S_next_dut_q.delete(0);
            S1_next_ref_q.delete(0); S1_next_dut_q.delete(0); Count_next_ref_q.delete(0); Count_next_dut_q.delete(0);
            Wait_next_ref_q.delete(0); Wait_next_dut_q.delete(0); done_ref_q.delete(0); done_dut_q.delete(0);
            counting_ref_q.delete(0); counting_dut_q.delete(0); shift_ena_ref_q.delete(0); shift_ena_dut_q.delete(0);
        end

        d_q.push_back(d); done_counting_q.push_back(done_counting); ack_q.push_back(ack); state_q.push_back(state);
        B3_next_ref_q.push_back(B3_next_ref); B3_next_dut_q.push_back(B3_next_dut);
        S_next_ref_q.push_back(S_next_ref); S_next_dut_q.push_back(S_next_dut);
        S1_next_ref_q.push_back(S1_next_ref); S1_next_dut_q.push_back(S1_next_dut);
        Count_next_ref_q.push_back(Count_next_ref); Count_next_dut_q.push_back(Count_next_dut);
        Wait_next_ref_q.push_back(Wait_next_ref); Wait_next_dut_q.push_back(Wait_next_dut);
        done_ref_q.push_back(done_ref); done_dut_q.push_back(done_dut);
        counting_ref_q.push_back(counting_ref); counting_dut_q.push_back(counting_dut);
        shift_ena_ref_q.push_back(shift_ena_ref); shift_ena_dut_q.push_back(shift_ena_dut);

        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            if (!first_mismatch_displayed) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %d cycles of simulation:", d_q.size());
                for (int i = 0; i < d_q.size(); i++) begin
                    $display("Cycle %d, d=%b, done_cnt=%b, ack=%b, state=%h, B3_n_ref=%b, B3_n_dut=%b, S_n_ref=%b, S_n_dut=%b, S1_n_ref=%b, S1_n_dut=%b, C_n_ref=%b, C_n_dut=%b, W_n_ref=%b, W_n_dut=%b, done_ref=%b, done_dut=%b, cnt_ref=%b, cnt_dut=%b, sh_ref=%b, sh_dut=%b",
                        i, d_q[i], done_counting_q[i], ack_q[i], state_q[i], 
                        B3_next_ref_q[i], B3_next_dut_q[i], S_next_ref_q[i], S_next_dut_q[i], 
                        S1_next_ref_q[i], S1_next_dut_q[i], Count_next_ref_q[i], Count_next_dut_q[i], 
                        Wait_next_ref_q[i], Wait_next_dut_q[i], done_ref_q[i], done_dut_q[i], 
                        counting_ref_q[i], counting_dut_q[i], shift_ena_ref_q[i], shift_ena_dut_q[i]);
                end
                first_mismatch_displayed = 1;
            end
        end

        // Original error counting logic
        if (B3_next_ref !== ( B3_next_ref ^ B3_next_dut ^ B3_next_ref ))
        begin if (stats1.errors_B3_next == 0) stats1.errortime_B3_next = $time;
            stats1.errors_B3_next = stats1.errors_B3_next+1'b1; end
        if (S_next_ref !== ( S_next_ref ^ S_next_dut ^ S_next_ref ))
        begin if (stats1.errors_S_next == 0) stats1.errortime_S_next = $time;
            stats1.errors_S_next = stats1.errors_S_next+1'b1; end
        if (S1_next_ref !== ( S1_next_ref ^ S1_next_dut ^ S1_next_ref ))
        begin if (stats1.errors_S1_next == 0) stats1.errortime_S1_next = $time;
            stats1.errors_S1_next = stats1.errors_S1_next+1'b1; end
        if (Count_next_ref !== ( Count_next_ref ^ Count_next_dut ^ Count_next_ref ))
        begin if (stats1.errors_Count_next == 0) stats1.errortime_Count_next = $time;
            stats1.errors_Count_next = stats1.errors_Count_next+1'b1; end
        if (Wait_next_ref !== ( Wait_next_ref ^ Wait_next_dut ^ Wait_next_ref ))
        begin if (stats1.errors_Wait_next == 0) stats1.errortime_Wait_next = $time;
            stats1.errors_Wait_next = stats1.errors_Wait_next+1'b1; end
        if (done_ref !== ( done_ref ^ done_dut ^ done_ref ))
        begin if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done = stats1.errors_done+1'b1; end
        if (counting_ref !== ( counting_ref ^ counting_dut ^ counting_ref ))
        begin if (stats1.errors_counting == 0) stats1.errortime_counting = $time;
            stats1.errors_counting = stats1.errors_counting+1'b1; end
        if (shift_ena_ref !== ( shift_ena_ref ^ shift_ena_dut ^ shift_ena_ref ))
        begin if (stats1.errors_shift_ena == 0) stats1.errortime_shift_ena = $time;
            stats1.errors_shift_ena = stats1.errors_shift_ena+1'b1; end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_B3_next) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "B3_next", stats1.errors_B3_next, stats1.errortime_B3_next);
        else $display("Hint: Output '%s' has no mismatches.", "B3_next");
        if (stats1.errors_S_next) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "S_next", stats1.errors_S_next, stats1.errortime_S_next);
        else $display("Hint: Output '%s' has no mismatches.", "S_next");
        if (stats1.errors_S1_next) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "S1_next", stats1.errors_S1_next, stats1.errortime_S1_next);
        else $display("Hint: Output '%s' has no mismatches.", "S1_next");
        if (stats1.errors_Count_next) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Count_next", stats1.errors_Count_next, stats1.errortime_Count_next);
        else $display("Hint: Output '%s' has no mismatches.", "Count_next");
        if (stats1.errors_Wait_next) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Wait_next", stats1.errors_Wait_next, stats1.errortime_Wait_next);
        else $display("Hint: Output '%s' has no mismatches.", "Wait_next");
        if (stats1.errors_done) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "done", stats1.errors_done, stats1.errortime_done);
        else $display("Hint: Output '%s' has no mismatches.", "done");
        if (stats1.errors_counting) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "counting", stats1.errors_counting, stats1.errortime_counting);
        else $display("Hint: Output '%s' has no mismatches.", "counting");
        if (stats1.errors_shift_ena) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "shift_ena", stats1.errors_shift_ena, stats1.errortime_shift_ena);
        else $display("Hint: Output '%s' has no mismatches.", "shift_ena");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule