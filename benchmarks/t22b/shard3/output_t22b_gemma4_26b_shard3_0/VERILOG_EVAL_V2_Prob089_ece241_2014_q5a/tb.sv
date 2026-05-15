`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic x,
    output logic areset,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    task reset_test(input async=0);
        bit arfail, srfail, datafail;
    
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
    
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
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

    initial begin
        x <= 0;
        reset <= 1;
        @(posedge clk) reset <= 0; x <= 1;
        @(posedge clk) x <= 0;
        reset_test(1);
        
        @(negedge clk) wavedrom_start();
            @(posedge clk) {reset,x} <= 2'h2;
            @(posedge clk) {reset,x} <= 2'h0;
            @(posedge clk) {reset,x} <= 2'h0;
            @(posedge clk) {reset,x} <= 2'h1;
            @(posedge clk) {reset,x} <= 2'h0;
            @(posedge clk) {reset,x} <= 2'h1;
            @(posedge clk) {reset,x} <= 2'h1;
            @(posedge clk) {reset,x} <= 2'h0;
            @(posedge clk) {reset,x} <= 2'h0;
        @(negedge clk) wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk)
            {reset,x} <= {($random&31) == 0, ($random&1)==0 };

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
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic areset;
    logic x;
    logic z_ref;
    logic z_dut;

    // Queues for mismatch reporting
    logic x_q [$];
    logic areset_q [$];
    logic z_ref_q [$];
    logic z_dut_q [$];
    localparam MAX_QUEUE_SIZE = 10;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,x,z_ref,z_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .areset,
        .x 
    );

    // Reference module placeholder - in a real scenario this is provided
    module RefModule (input clk, input areset, input x, output logic z);
        // Implementation of 2's complementer for verification
        logic [31:0] val;
        logic [31:0] inv;
        always @(posedge clk or posedge areset) begin
            if (areset) {val, z} <= 0;
            else begin
                val <= {x, val[30:0]};
                // This is a simplified placeholder for the reference logic
                // In actual use, the RefModule would be a golden model.
            end
        end
    endmodule

    RefModule good1 (
        .clk,
        .areset,
        .x,
        .z(z_ref) 
    );
        
    TopModule top_module1 (
        .clk,
        .areset,
        .x,
        .z(z_dut) 
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    always @(posedge clk, negedge clk) begin
        // Maintain Queues
        if (x_q.size() >= MAX_QUEUE_SIZE) begin
            x_q.delete(0);
            areset_q.delete(0);
            z_ref_q.delete(0);
            z_dut_q.delete(0);
        end
        x_q.push_back(x);
        areset_q.push_back(areset);
        z_ref_q.push_back(z_ref);
        z_dut_q.push_back(z_dut);

        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Display mismatch details only on the FIRST mismatch
            if (stats1.errors == 1) begin
                $display("\n*** FIRST MISMATCH DETECTED AT TIME %t ***", $time);
                $display("Queue contents (last %0d cycles):", x_q.size());
                for (int i = 0; i < x_q.size(); i++) begin
                    $display("Cycle %0d: reset=%b, x=%b, z_ref=%b, z_dut=%b", 
                             i, areset_q[i], x_q[i], z_ref_q[i], z_dut_q[i]);
                end
            end
        end

        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z+1'b1; 
        end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output '%s' has no mismatches.", "z");

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