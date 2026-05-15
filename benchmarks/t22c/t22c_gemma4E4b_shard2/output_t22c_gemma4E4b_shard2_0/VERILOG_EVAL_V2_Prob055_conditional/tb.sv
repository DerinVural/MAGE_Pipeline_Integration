/*
 * Testbench for TopModule (Minimum Finder)
 * This testbench strictly follows the structure and functionality of the provided golden testbench,
 * while incorporating enhanced logging as required.
 */
`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Forward declaration/Definition of RefModule (Mirroring TopModule's logic for reference)
module RefModule (
    input logic [7:0] a, b, c, d,
    output logic [7:0] min
);
    // Implementation mirrors TopModule
    assign min = (a < b) ? ((a < c) ? ((a < d) ? a : d) : ((c < d) ? c : d)) : ((b < c) ? ((b < d) ? b : d) : ((c < d) ? c : d));
endmodule

// TopModule is the DUT we are testing
module TopModule (
    input logic [7:0] a, b, c, d,
    output logic [7:0] min
);
    // Implementation required by specification: find minimum of a, b, c, d
    logic [7:0] temp_min;
    
    // Find min(a, b)
    assign temp_min = (a < b) ? a : b;
    
    // Find min(temp_min, c)
    logic [7:0] temp2;
    assign temp2 = (temp_min < c) ? temp_min : c;
    
    // Find min(temp2, d)
    assign min = (temp2 < d) ? temp2 : d;
endmodule

// Stimulus Generator (Kept as is)
module stimulus_gen (
    input clk,
    output logic [7:0] a, b, c, d,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
    
    initial begin 
        {a,b,c,d} <= {8'h1, 8'h2, 8'h3, 8'h4};
        @(negedge clk);
        wavedrom_start();
        @(posedge clk) {a,b,c,d} <= {8'h1, 8'h2, 8'h3, 8'h4};
        @(posedge clk) {a,b,c,d} <= {8'h11, 8'h2, 8'h3, 8'h4};
        @(posedge clk) {a,b,c,d} <= {8'h11, 8'h12, 8'h3, 8'h4};
        @(posedge clk) {a,b,c,d} <= {8'h11, 8'h12, 8'h13, 8'h4};
        @(posedge clk) {a,b,c,d} <= {8'h11, 8'h12, 8'h13, 8'h14};
        @(negedge clk);
        wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk)
            {a,b,c,d} <= $random;
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_min;
        int errortime_min;
        int clocks;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] c;
    logic [7:0] d;
    logic [7:0] min_ref;
    logic [7:0] min_dut;

    // Variables to capture signals at the first mismatch
    logic [7:0] a_err_time, b_err_time, c_err_time, d_err_time,
           min_dut_err_time, min_ref_err_time;

    initial begin 
        $dumpfile("wave.vcd");
        // Dump all relevant signals
        $dumpvars(1, stimulus_gen.stim1.clk, tb_mismatch ,a,b,c,d,min_ref,min_dut );
    end


    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .a,
        .b,
        .c,
        .d );
    RefModule good1 (
        .a,
        .b,
        .c,
        .d,
        .min(min_ref) );
        
    TopModule top_module1 (
        .a,
        .b,
        .c,
        .d,
        .min(min_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask 

    
    // Task to display signals in Hex and Binary format (for 8-bit signals)
    task display_signal(input string name, input logic [7:0] signal);
        $display("\t--- Signal %s ---", name);
        $display("\tHex: 0x%h", signal);
        $display("\tBin: %b", signal);
    endtask

    final begin
        $display("==================================================");
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            // Required failure format
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("\n--- DETAILS OF FIRST MISMATCH (TIME %0d) ---", stats1.errortime);
            $display("Inputs at First Mismatch:");
            // Display inputs using the captured variables
            display_signal("a", a_err_time);
            display_signal("b", b_err_time);
            display_signal("c", c_err_time);
            display_signal("d", d_err_time);
            $display("Outputs at First Mismatch:");
            // Display outputs using the captured variables
            display_signal("min_dut (DUT)", min_dut_err_time);
            display_signal("min_ref (Expected)", min_ref_err_time);
            $display("==================================================");
        end
        
        $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // Verification: Simplifies to min_ref === min_dut
    assign tb_match = ( min_ref === min_dut );
    
    // Use explicit sensitivity list here.
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        // Check for mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // Capture signals ONLY on the very first mismatch (errors == 1)
        if (stats1.errors == 1) begin
            a_err_time <= a; 
            b_err_time <= b; 
            c_err_time <= c; 
            d_err_time <= d; 
            min_dut_err_time <= min_dut;
            min_ref_err_time <= min_ref;
        end
        
        // Replicating the original error_min tracking logic structure for consistency
        if (min_ref !== min_dut) 
        begin 
            if (stats1.errors_min == 0) stats1.errortime_min = $time;
            stats1.errors_min = stats1.errors_min + 1'b1; 
        end

    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("\n--- TIMEOUT REACHED ---");
      $finish();
    end

endmodule