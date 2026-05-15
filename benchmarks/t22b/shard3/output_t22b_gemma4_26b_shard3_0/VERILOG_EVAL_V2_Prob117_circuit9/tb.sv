`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input logic clk,
    output logic a,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    initial begin
        a <= 1;
        @(negedge clk) {a} <= 1;
        @(negedge clk) wavedrom_start("Unknown circuit");
        repeat(2) @(posedge clk);
        @(posedge clk) {a} <= 0;
        repeat(11) @(posedge clk);
        @(negedge clk) a <= 1;
        repeat(5) @(posedge clk, negedge clk);
        a <= 0;
        repeat(4) @(posedge clk);
        wavedrom_stop();

        repeat(200) @(posedge clk, negedge clk)
            a <= &((5)'($urandom));
        $finish;
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

    logic a;
    logic [2:0] q_ref;
    logic [2:0] q_dut;

    // Queues for mismatch history
    logic a_q [$];
    logic [2:0] q_dut_q [$];
    logic [2:0] q_ref_q [$];
    localparam MAX_QUEUE_SIZE = 10;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, a, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .a
    );

    // RefModule is assumed to be provided by the environment
    RefModule good1 (
        .clk,
        .a,
        .q(q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .a,
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
        // Maintain Queue
        if (a_q.size() >= MAX_QUEUE_SIZE) begin
            a_q.delete(0);
            q_dut_q.delete(0);
            q_ref_q.delete(0);
        end
        a_q.push_back(a);
        q_dut_q.push_back(q_dut);
        q_ref_q.push_back(q_ref);

        stats1.clocks++;
        
        // Original error counting logic
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;

            // Display first mismatch details
            if (stats1.errors_q == 1) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %d cycles of simulation history:", a_q.size());
                for (int i = 0; i < a_q.size(); i++) begin
                    $display("Cycle %d, a=%b, got_q=%h (%b), exp_q=%h (%b)", 
                        i, a_q[i], q_dut_q[i], q_dut_q[i], q_ref_q[i], q_ref_q[i]);
                end
            end
        end
    end

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
            $display("Hint: Output 'q' has no mismatches.");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule