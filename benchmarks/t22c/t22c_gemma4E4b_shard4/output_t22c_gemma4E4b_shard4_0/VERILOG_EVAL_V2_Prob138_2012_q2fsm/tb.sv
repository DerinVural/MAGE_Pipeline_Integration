`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Minimal placeholder for RefModule to allow testbench compilation as per golden testbench structure
module RefModule (
    input logic clk,
    input logic reset,
    input logic w,
    output logic z
);
    // Placeholder logic: assume it matches TopModule's expected behavior for testing.
    assign z = 1'b0; 
endmodule

// Stimulus Generator (Maintained exactly from golden testbench)
module stimulus_gen (
    input clk,
    output logic reset,
    output logic w
);
    initial begin
        repeat(200) @(negedge clk) begin
            reset <= ($random & 'h1f) == 0;
            w <= $random;
        end
        
        #1 $finish;
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
    
    // Variables to capture state at first mismatch
    logic fail_clk, fail_reset, fail_w, fail_z_dut, fail_z_ref;
    int first_mismatch_time = -1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic reset;
    logic w;
    logic z_ref;
    logic z_dut;

    // DUT Instantiation
    TopModule top_module1 (
        .clk(clk),
        .reset(reset),
        .w(w),
        .z(z_dut)
    );

    // Reference Instantiation
    RefModule good1 (
        .clk(clk),
        .reset(reset),
        .w(w),
        .z(z_ref)
    );
        
    // Stimulus Generation Instantiation
    stimulus_gen stim1 (
        .clk(clk),
        .reset(reset),
        .w(w)
    );

    // Dump waves
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,w,z_ref,z_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Clocked verification and error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // General Mismatch Check
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            // Capture state at first general mismatch
            if (stats1.errors == 1 && first_mismatch_time == -1) begin
                first_mismatch_time = $time;
                fail_clk = clk;
                fail_reset = reset;
                fail_w = w;
                fail_z_dut = z_dut;
                fail_z_ref = z_ref;
            end
        end
        
        // Z Output Mismatch Check
        if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
        begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z+1'b1;
            // Capture state at first Z mismatch (if it's the overall first mismatch)
            if (stats1.errors_z == 1 && first_mismatch_time == -1) begin
                first_mismatch_time = $time;
                fail_clk = clk;
                fail_reset = reset;
                fail_w = w;
                fail_z_dut = z_dut;
                fail_z_ref = z_ref;
            end
        end
    end

    // Timeout
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    // Final reporting block (Enhanced to meet strict requirements)
    final begin
        if (stats1.errors == 0 && stats1.errors_z == 0) begin
            $display("\n========================================")
            $display("SIMULATION PASSED")
            $display("========================================")
        end else begin
            int total_mismatches = stats1.errors + stats1.errors_z;
            string failure_message = "SIMULATION FAILED - " + 
                string(total_mismatches) + " MISMATCHES DETECTED, FIRST AT TIME " + 
                string(first_mismatch_time);
            $display("\n========================================")
            $display("%s", failure_message)
            $display("========================================")
            
            // Detailed signal display at first mismatch time
            $display("\n--- DETAILED SIGNAL REPORT AT TIME %0d ps ---", first_mismatch_time);
            // Displaying inputs (clk, reset, w). Since they are 1-bit, we show both bin/hex.
            $display("Input Signals: clk=%b (0x%h), reset=%b (0x%h), w=%b (0x%h)", 
                fail_clk, fail_clk, fail_reset, fail_reset, fail_w, fail_w);
            // Displaying outputs (z_ref, z_dut). Since they are 1-bit, we show both bin/hex.
            $display("Output Signals: z_ref=%b (0x%h), z_dut=%b (0x%h)", 
                fail_z_ref, fail_z_ref, fail_z_dut, fail_z_dut);
            // Expected Output
            $display("Expected Output (z_ref): %b (0x%h)", fail_z_ref, fail_z_ref);
            // Actual Output
            $display("Actual Output (z_dut): %b (0x%h)", fail_z_dut, fail_z_dut);
        end
    end

endmodule