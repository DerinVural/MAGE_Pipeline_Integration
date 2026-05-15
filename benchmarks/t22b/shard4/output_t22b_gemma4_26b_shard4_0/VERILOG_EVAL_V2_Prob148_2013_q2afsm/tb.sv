`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic resetn,
    output logic [2:0] r,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input tb_match
);
    reg reset;
    assign resetn = ~reset;

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
        r <= 0;
        @(posedge clk);
        
        r <= 1;
        reset_test();
        
        r <= 0;
        wavedrom_start("");
        @(posedge clk) r <= 0;
        @(posedge clk) r <= 7;
        @(posedge clk) r <= 7;
        @(posedge clk) r <= 7;
        @(posedge clk) r <= 6;
        @(posedge clk) r <= 6;
        @(posedge clk) r <= 6;
        @(posedge clk) r <= 4;
        @(posedge clk) r <= 4;
        @(posedge clk) r <= 4;
        @(posedge clk) r <= 0;
        @(posedge clk) r <= 0;
        @(posedge clk) r <= 4;
        @(posedge clk) r <= 6;
        @(posedge clk) r <= 7;
        @(posedge clk) r <= 7;
        @(posedge clk) r <= 7;
        @(negedge clk);
        wavedrom_stop();
        
        @(posedge clk);
        reset <= 0;
        @(posedge clk);
        @(posedge clk);
        
        repeat(500) @(negedge clk) begin
            reset <= ($random & 63) == 0;
            r <= $random;
        end
        
        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_g;
        int errortime_g;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic resetn;
    logic [2:0] r;
    logic [2:0] g_ref;
    logic [2:0] g_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, resetn, r, g_ref, g_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    // Queues for mismatch reporting
    localparam MAX_QUEUE_SIZE = 10;
    logic [2:0] r_q [$];
    logic resetn_q [$];
    logic [2:0] g_ref_q [$];
    logic [2:0] g_dut_q [$];
    bit first_mismatch_done = 0;

    stimulus_gen stim1 (
        .clk,
        .*,
        .resetn,
        .r
    );

    RefModule good1 (
        .clk,
        .resetn,
        .r,
        .g(g_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .resetn,
        .r,
        .g(g_dut)
    );

    assign tb_match = ( { g_ref } === ( { g_ref } ^ { g_dut } ^ { g_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Manage Queues
        if (r_q.size() >= MAX_QUEUE_SIZE) begin
            r_q.delete(0);
            resetn_q.delete(0);
            g_ref_q.delete(0);
            g_dut_q.delete(0);
        end
        r_q.push_back(r);
        resetn_q.push_back(resetn);
        g_ref_q.push_back(g_ref);
        g_dut_q.push_back(g_dut);

        // Error Counting
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Mismatch Reporting
            if (!first_mismatch_done) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %0d cycles of simulation:", r_q.size());
                for (int i = 0; i < r_q.size(); i++) begin
                    $display("Cycle %0d, resetn=%b, r=%h(%b), g_ref=%h(%b), g_dut=%h(%b)",
                        i, resetn_q[i], r_q[i], r_q[i], g_ref_q[i], g_ref_q[i], g_dut_q[i], g_dut_q[i]);
                end
                first_mismatch_done = 1;
            end
        end

        if (g_ref !== ( g_ref ^ g_dut ^ g_ref )) begin 
            if (stats1.errors_g == 0) stats1.errortime_g = $time;
            stats1.errors_g = stats1.errors_g + 1;
        end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_g) 
            $display("Hint: Output 'g' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_g, stats1.errortime_g);
        else 
            $display("Hint: Output 'g' has no mismatches.");

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