`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic reset
);

    initial begin
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 31);
        end
        @(posedge clk) reset <= 1'b0;
        repeat(200000) @(posedge clk);
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
    logic [31:0] q_ref;
    logic [31:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,q_ref,q_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
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

    // Queue for mismatch reporting
    logic clk_q [$];
    logic reset_q [$];
    logic [31:0] q_dut_q [$];
    logic [31:0] q_ref_q [$];
    localparam MAX_QUEUE_SIZE = 10;
    bit first_mismatch_reported = 0;

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Manage Queue
        if (clk_q.size() >= MAX_QUEUE_SIZE) begin
            clk_q.delete(0);
            reset_q.delete(0);
            q_dut_q.delete(0);
            q_ref_q.delete(0);
        end
        clk_q.push_back(clk);
        reset_q.push_back(reset);
        q_dut_q.push_back(q_dut);
        q_ref_q.push_back(q_ref);

        // Statistics and Error Counting
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;
            
            // Display first mismatch details
            if (!first_mismatch_reported) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %d cycles of simulation:", clk_q.size());
                for (int i = 0; i < clk_q.size(); i++) begin
                    $display("Cycle %d, reset %b, q_dut %h (%b), q_ref %h (%b)",
                        i, reset_q[i], q_dut_q[i], q_dut_q[i], q_ref_q[i], q_ref_q[i]);
                end
                first_mismatch_reported = 1;
            end
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule