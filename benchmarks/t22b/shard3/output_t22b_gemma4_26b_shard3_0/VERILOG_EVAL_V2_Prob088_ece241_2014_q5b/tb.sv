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

    // Added ports as requested by golden testbench
    initial wavedrom_enable = 0;
    initial wavedrom_title = 0;

    task wavedrom_start(input[511:0] title = "");
        wavedrom_enable = 1;
        wavedrom_title = title;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable = 0;
    endtask    

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
    initial forever #5 clk = ~clk;

    logic areset;
    logic x;
    logic z_ref;
    logic z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, areset, x, z_ref, z_dut);
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .areset,
        .x,
        .wavedrom_title,
        .wavedrom_enable
    );

    // RefModule is assumed to be provided/defined elsewhere in the environment
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
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Display first mismatch details
            if (stats1.errors == 1) begin
                $display("Mismatch detected!");
                $display("Time: %0t | x=%b, areset=%b | Expected z=%b, Actual z=%b", $time, x, areset, z_ref, z_dut);
            end
        end
        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1'b1; 
        end
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors_z == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
        end

        if (stats1.errors_z) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else 
            $display("Hint: Output '%s' has no mismatches.", "z");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule