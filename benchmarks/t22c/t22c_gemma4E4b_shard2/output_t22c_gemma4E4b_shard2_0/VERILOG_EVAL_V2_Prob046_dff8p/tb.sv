`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- DUT Implementation (TopModule) ---
// This definition is necessary for the testbench to compile and run.
module TopModule (
    input logic clk,
    input logic reset,
    input logic [7:0] d,
    output logic [7:0] q
);
    // 8 D flip-flops with active high synchronous reset, reset value 0x34, triggered on negative edge of clk
    logic [7:0] q_reg;
    
    // Sequential logic implementation (DFFs triggered by negative clock edge)
    always @(negedge clk)
    begin
        if (reset == 1'b1)
        begin
            // Synchronous active high reset to 0x34
            q_reg <= 8'h34;
        end
        else
        begin
            // Normal data capture on negative edge
            q_reg <= d;
        end
    end
    
    // Output assignment
    assign q = q_reg;
endmodule

// --- Stimulus Generator Module (Copied from Golden Testbench) ---
module stimulus_gen (
    input clk,
    output reg [7:0] d, output reg reset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);

    // Add two ports to module stimulus_gen:
    //    output [511:0] wavedrom_title
    //    output reg wavedrom_enable

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
        // Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
        // a functionality error than the reset being implemented asynchronously.
    
    endtask

    
    initial begin
        reset <= 1;
        d <= $random;
        @(negedge clk);
        @(negedge clk);
        wavedrom_start("Synchronous active-high reset");
        reset_test();
        repeat(10) @(negedge clk)
            d <= $random;
        wavedrom_stop();

        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 15);
            d <= $random;
        end
    
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

    logic [7:0] d;
    logic reset;
    logic [7:0] q_ref;
    logic [7:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,d,reset,q_ref,q_dut );
    end


    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .d,
        .reset );
    RefModule good1 (
        .clk,
        .d,
        .reset,
        .q(q_ref) );
        
    TopModule top_module1 (
        .clk,
        .d,
        .reset,
        .q(q_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask	

    
    // Variables to capture first mismatch data
    integer first_mismatch_time = -1;
    logic [7:0] first_mismatch_d = 8'h00;
    logic first_mismatch_reset = 0;
    logic [7:0] first_mismatch_q_ref = 8'h00;
    logic [7:0] first_mismatch_q_dut = 8'h00;

    
    final begin
        // Final required output format
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
        
        // Retaining original specific hints if they exist
        if (stats1.errors_q) $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output 'q' has no mismatches.");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
    
    // Logic for error counting and capturing first mismatch data
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Check for general mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                first_mismatch_time = $time;
                first_mismatch_d = d;
                first_mismatch_reset = reset;
                first_mismatch_q_ref = q_ref;
                first_mismatch_q_dut = q_dut;
            end
            stats1.errors++;
        end
        
        // Check for specific output mismatch (original logic preserved)
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q+1'b1;
        end
    end

    // Display first mismatch details upon simulation completion (after final block finishes)
    initial begin
        waitfor (finish);
        if (first_mismatch_time != -1) begin
            $display("\n====================================================\n");
            $display("!!! FIRST MISMATCH DETECTED !!!");
            $display("Time: %0d ps", first_mismatch_time);
            $display("------------------------------------------------------");
            $display("INPUTS:");
            $display("  clk: %b", clk);
            $display("  reset: %b", first_mismatch_reset);
            // Display d in HEX and BIN
            $display("  d: HEX=%h, BIN=%b", first_mismatch_d, first_mismatch_d);
            $display("OUTPUTS:");
            // Display q_DUT in HEX and BIN
            $display("  q_DUT: HEX=%h, BIN=%b", first_mismatch_q_dut, first_mismatch_q_dut);
            // Display q_REF in HEX and BIN
            $display("  q_REF (Expected): HEX=%h, BIN=%b", first_mismatch_q_ref, first_mismatch_q_ref);
            $display("====================================================\n");
        end
    end
    
    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule