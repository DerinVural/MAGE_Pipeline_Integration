`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13


// Stimulus Generator (Kept as is)
module stimulus_gen (
    input clk,
    output logic [1023:0] in,
    output logic [7:0] sel
);

    always @(posedge clk, negedge clk) begin
        for (int i=0;i<32; i++) begin
            // Corrected: used 'in' instead of 'is'
            in[i*32+:32] <= $random;
        end
        sel <= $random;
    end
    
    initial begin
        repeat(1000) @(negedge clk);
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;

        int clocks;
    } stats;
    
    stats stats1;
    
    
    // Signals for waveform dumping (kept from original TB)
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [1023:0] in;
    logic [7:0] sel;
    logic [3:0] out_ref;
    logic [3:0] out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        // Corrected dumpvars arguments
        $dumpvars(1, stim1.clk, tb_mismatch ,in,sel,out_ref,out_dut );
    end


    wire tb_match;     // Verification
    wire tb_mismatch = ~tb_match;
    
    // Instantiation 1: Stimulus Generator
    stimulus_gen stim1 (
        .clk, 
        .in, 
        .sel 
    );
    
    // Instantiation 2: Reference Module (Assuming RefModule exists)
    RefModule good1 (
        .in, 
        .sel, 
        .out(out_ref) );
        
    // Instantiation 3: DUT
    TopModule top_module1 (
        .in, 
        .sel, 
        .out(out_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask 

    
    // Tasks and Initial Blocks
    initial begin
        // Wait for initial settling time
        @(negedge clk);
        // Wait for a few cycles to ensure stimulus_gen is running
        repeat(10) @(negedge clk);
    end

    
    // Enhanced Final Block
    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            // Required final failure message format
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
        
        // Displaying the old hint style logic for completeness/debugging, as in the golden TB
        if (stats1.errors_out) $display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out, stats1.errortime_out);
        else $display("Hint: Output 'out' has no mismatches.");
        
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // Verification Logic
    // This XOR logic is maintained exactly as per the golden testbench
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                
                // --- Detailed Display at FIRST mismatch --- 
                $display("========================================================================");
                $display("!!! FIRST MISMATCH DETECTED AT TIME %0d ps !!!", $time);
                
                $display("Input Signals:");
                // in is 1024 bits, display in HEX as binary is too long
                $display("  in (1024 bits): 0x%h", in);
                $display("  sel (8 bits): 0x%h | Binary: %b", sel, sel);
                
                $display("Output Signals:");
                // out_dut and out_ref are 4 bits, display both HEX and BINARY
                $display("  DUT Output (out_dut) (4 bits): 0x%h | Binary: %b", out_dut, out_dut);
                $display("  Reference Output (out_ref) (4 bits): 0x%h | Binary: %b", out_ref, out_ref);
                $display("========================================================================");
            end
            stats1.errors++;
        end
        
        // Secondary error check (maintained from golden TB)
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out+1'b1; 
        end

    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule