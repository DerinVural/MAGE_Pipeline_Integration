`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic x,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    initial begin
        x <= 0;
        @(negedge clk) wavedrom_start();
        @(posedge clk) x <= 1'h0;
        @(posedge clk) x <= 1'h0;
        @(posedge clk) x <= 1'h0;
        @(posedge clk) x <= 1'h0;
        @(posedge clk) x <= 1'h1;
        @(posedge clk) x <= 1'h1;
        @(posedge clk) x <= 1'h1;
        @(posedge clk) x <= 1'h1;
        @(negedge clk) wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk)
            x <= $random;

        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic x;
    logic z_ref;
    logic z_dut;

    // Queues for mismatch reporting
    logic [0:0] q_x [$];
    logic [0:0] q_z_dut [$];
    logic [0:0] q_z_ref [$];
    localparam MAX_QUEUE_SIZE = 10;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, x, z_ref, z_dut);
    end

    wire tb_match; 
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .x,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    // RefModule is assumed to be provided by the environment as per golden TB
    RefModule good1 (
        .clk,
        .x,
        .z(z_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .x,
        .z(z_dut)
    );

    // Mismatch detection and Queue logic
    always @(posedge clk, negedge clk) begin
        // Maintain Queue
        if (q_x.size() >= MAX_QUEUE_SIZE) begin
            q_x.delete(0);
            q_z_dut.delete(0);
            q_z_ref.delete(0);
        end
        q_x.push_back(x);
        q_z_dut.push_back(z_dut);
        q_z_ref.push_back(z_ref);

        // Error Counting
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (z_ref !== z_dut) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1;

            // Display first mismatch details
            if (stats1.errors_z == 1) begin
                $display("Mismatch detected at time %t", $time);
                $display("\nLast %0d cycles of simulation:", q_x.size());
                for (int i = 0; i < q_x.size(); i++) begin
                    $display("Cycle %0d, x=%b, got_z=%b, exp_z=%b", 
                             i, q_x[i], q_z_dut[i], q_z_ref[i]);
                end
            end
        end
    end

    // Verification logic
    assign tb_match = ( {z_ref} === ({z_ref} ^ {z_dut} ^ {z_ref}) );

    final begin
        if (stats1.errors_z == 0) begin
            $display("SIMULATION PASSED");
            $display("Hint: Output 'z' has no mismatches.");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
            $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
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