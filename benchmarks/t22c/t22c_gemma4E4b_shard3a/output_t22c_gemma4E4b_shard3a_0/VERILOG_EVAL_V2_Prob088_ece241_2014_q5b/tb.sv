`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic x,
    output logic areset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;

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

    // Variables to capture state at first error
    logic capture_x_err = 0; 
    logic capture_z_err = 0;
    logic captured_x;
    logic captured_z_ref;
    logic captured_z_dut;

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
        .x );
    // Assuming RefModule exists and matches interface
    RefModule good1 (
        .clk,
        .areset,
        .x,
        .z(z_ref) );
        
    TopModule top_module1 (
        .clk,
        .areset,
        .x,
        .z(z_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    final begin
        $display("====================================================================");
        $display("SIMULATION SUMMARY:");
        $display("Total Clocks Simulated: %0d", stats1.clocks);
        $display("Total Mismatches (tb_match): %0d in %0d samples", stats1.errors, stats1.clocks);
        $display("Total Z Mismatches (z_ref vs z_dut): %0d in %0d samples", stats1.errors_z, stats1.clocks);

        if (stats1.errors > 0) begin
            // Requirement: Display detailed mismatch for X errors
            $display("SIMULATION FAILED - x MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime);
            $display("--- FIRST X MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
            // Displaying 1-bit signals in both bin and hex format as requested
            $display("Input x:  %0b (0x%h)", captured_x, captured_x);
            $display("Ref z:    %0b (0x%h)", captured_z_ref, captured_z_ref);
            $display("DUT z:    %0b (0x%h)", captured_z_dut, captured_z_dut);
        end else if (stats1.errors_z > 0) begin
            // If X passed, but Z failed, we still need to report failure if Z failed, but the specific failure message must follow the X failure format if possible, or a derived one.
            // Since the requirement only specifies the X failure message format, if X is clean, we use a derived message structure.
            $display("SIMULATION FAILED - z MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errortime_z);
            $display("--- FIRST Z MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime_z);
            $display("Input x:  %0b (0x%h)", captured_x, captured_x);
            $display("Ref z:    %0b (0x%h)", captured_z_ref, captured_z_ref);
            $display("DUT z:    %0b (0x%h)", captured_z_dut, captured_z_dut);
        end
        
        if (stats1.errors == 0 && stats1.errors_z == 0) begin
            $display("SIMULATION PASSED");
        end
        
        $display("====================================================================");
        
        $finish;
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    // Since z_ref is 1-bit, {z_ref} is sufficient.
    assign tb_match = ( z_ref === ( z_ref ^ z_dut ^ z_ref ) );
    // Use explicit sensitivity list here.
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        // Capture state for error reporting
        if (!tb_match && stats1.errors == 0) begin
            stats1.errortime = $time;
            captured_x = x;
            captured_z_ref = z_ref;
            captured_z_dut = z_dut;
        end
        
        // Check for z mismatch
        if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
        begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            captured_x = x; // Capture X corresponding to this z error
            captured_z_ref = z_ref;
            captured_z_dut = z_dut;
            stats1.errors_z = stats1.errors_z+1'b1; 
        end
        
        // Error counting (original logic)
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

    end

   // add timeout after 100K cycles
   initial begin
     #1000000
     // If simulation hasn't finished by timeout, report based on errors found
     if (stats1.errors == 0 && stats1.errors_z == 0) begin
         $display("TIMEOUT REACHED. SIMULATION PASSED (No errors found before timeout).");
     end else begin
         $display("TIMEOUT REACHED. SIMULATION FAILED (Errors detected before timeout).");
     end
     $finish();
   end

endmodule