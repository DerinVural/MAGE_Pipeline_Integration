`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Placeholder for RefModule to satisfy golden testbench structure
module RefModule (
    input clk,
    input [7:0] d,
    input areset,
    output [7:0] q
);
    // Placeholder implementation: Q follows D synchronously, reset to 0
    reg [7:0] q_r;
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            q_r <= 8'b0;
        end else begin
            q_r <= d;
        end
    end
    assign q = q_r;
endmodule

module stimulus_gen (
    input clk,
    output reg [7:0] d, output areset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
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
        reset <= 1;
        d <= $random;
        @(negedge clk);
        @(negedge clk);
        wavedrom_start("Asynchronous active-high reset");
        reset_test(1);
        repeat(7) @(negedge clk) d <= $random;
        @(posedge clk) reset <= 1;
        @(negedge clk) reset <= 0; d <= $random;
        repeat(2) @(negedge clk) d <= $random;
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
        // Variables to capture state at first mismatch
        logic [7:0] d_mismatch_state;
        logic areset_mismatch_state;
        logic [7:0] q_ref_mismatch_state;
        logic [7:0] q_dut_mismatch_state;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [7:0] d;
    logic areset;
    logic [7:0] q_ref;
    logic [7:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, tb);
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk, 
        .d, .areset, 
        .wavedrom_title, .wavedrom_enable, 
        .tb_match
    );
    
    RefModule good1 (
        .clk, 
        .d, 
        .areset, 
        .q(q_ref) 
    );
        
    TopModule top_module1 (
        .clk, 
        .d, 
        .areset, 
        .q(q_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
    
    // Mismatch detection and state tracking
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Track errors based on the original logic
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Capture state ONLY at the first mismatch
            if (stats1.errors == 1)
            begin
                stats1.d_mismatch_state <= d;
                stats1.areset_mismatch_state <= areset;
                stats1.q_ref_mismatch_state <= q_ref;
                stats1.q_dut_mismatch_state <= q_dut;
            end
        end
        
        // Original Q mismatch logic
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q+1'b1; 
        end
    end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end

    // Final Reporting Block (Improved)
    final begin
        
        // 1. Report on Q specific errors (Original Logic)
        if (stats1.errors_q) 
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        else 
            $display("Hint: Output 'q' has no mismatches.");

        // 2. Report on Total errors and Time (Required Output)
        if (stats1.errors == 0)
        begin
            $display("SIMULATION PASSED");
        end
        else
        begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);

            // 3. Detailed display for the FIRST mismatch
            $display("\n--- FIRST MISMATCH DETAILS ---");
            
            // Display Inputs
            $display("Inputs at Time %0d ps:", stats1.errortime);
            // d is 8 bits
            $display("  d: HEX=%h, BIN=%b", stats1.d_mismatch_state, stats1.d_mismatch_state);
            $display("  areset: %b", stats1.areset_mismatch_state);
            
            // Display Outputs
            $display("Outputs at Time %0d ps:", stats1.errortime);
            // q_ref is 8 bits
            $display("  q_ref (Expected): HEX=%h, BIN=%b", stats1.q_ref_mismatch_state, stats1.q_ref_mismatch_state);
            // q_dut is 8 bits
            $display("  q_dut (Actual): HEX=%h, BIN=%b", stats1.q_dut_mismatch_state, stats1.q_dut_mismatch_state);
            
            // Display tb_match status
            $display("  tb_match status: %b", (stats1.q_ref_mismatch_state === stats1.q_dut_mismatch_state));
        end
        
        $display("\n--- SUMMARY ---");
        $display("Total mismatched samples: %1d out of %1d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end

endmodule