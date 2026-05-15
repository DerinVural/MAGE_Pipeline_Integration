`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic w, R, E, L
);

    initial begin
        {w,R,E,L} <= 4'b0;
        repeat(200) @(posedge clk, negedge clk) begin
            {w,R,E,L} <= $random;
        end
        
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

    logic w;
    logic R;
    logic E;
    logic L;
    logic Q_ref;
    logic Q_dut;

    // Queue for mismatch logging
    logic w_q [$];
    logic R_q [$];
    logic E_q [$];
    logic L_q [$];
    logic Q_ref_q [$];
    logic Q_dut_q [$];
    localparam MAX_QUEUE_SIZE = 10;
    bit first_mismatch_displayed = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,w,R,E,L,Q_ref,Q_dut );
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .w,
        .R,
        .E,
        .L 
    );

    // Note: RefModule is assumed to be provided in the environment
    RefModule good1 (
        .clk,
        .w,
        .R,
        .E,
        .L,
        .Q(Q_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .w,
        .R,
        .E,
        .L,
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
        // Manage Queues
        if (w_q.size() >= MAX_QUEUE_SIZE) begin
            w_q.delete(0);
            R_q.delete(0);
            E_q.delete(0);
            L_q.delete(0);
            Q_ref_q.delete(0);
            Q_dut_q.delete(0);
        end

        w_q.push_back(w);
        R_q.push_back(R);
        E_q.push_back(E);
        L_q.push_back(L);
        Q_ref_q.push_back(Q_ref);
        Q_dut_q.push_back(Q_dut);

        // Stats and Error Counting
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Display first mismatch details
            if (!first_mismatch_displayed) begin
                $display("\n[FIRST MISMATCH DETECTED at %t]", $time);
                $display("Last %0d cycles of simulation:", w_q.size());
                for (int i = 0; i < w_q.size(); i++) begin
                    $display("Cycle %0d: w=%b, R=%b, E=%b, L=%b | Exp Q=%b, Got Q=%b", 
                             i, w_q[i], R_q[i], E_q[i], L_q[i], Q_ref_q[i], Q_dut_q[i]);
                end
                first_mismatch_displayed = 1;
            end
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
        if (stats1.errors_Q) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Q", stats1.errors_Q, stats1.errortime_Q);
        else 
            $display("Hint: Output '%s' has no mismatches.", "Q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        
        if (stats1.errors == 0 && stats1.errors_Q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", 
                     (stats1.errors + stats1.errors_Q), 
                     (stats1.errors_Q > 0 ? stats1.errortime_Q : stats1.errortime));
        end
        
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule