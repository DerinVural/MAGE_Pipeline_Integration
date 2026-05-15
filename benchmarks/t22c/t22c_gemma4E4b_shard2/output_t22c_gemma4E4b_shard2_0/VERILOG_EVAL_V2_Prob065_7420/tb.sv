`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assume RefModule is defined elsewhere and implements the golden behavior
module RefModule (
    input p1a,
    input p1b,
    input p1c,
    input p1d,
    input p2a,
    input p2b,
    input p2c,
    input p2d,
    output p1y,
    output p2y
);
    // Placeholder logic: In a real scenario, this would contain the expected logic
    assign p1y = p1a & p1b; // Dummy
    assign p2y = p2c | p2d; // Dummy
endmodule

// TopModule implementation must match the interface derived from input_spec
module TopModule (
    input p1a,
    input p1b,
    input p1c,
    input p1d,
    input p2a,
    input p2b,
    input p2c,
    input p2d,
    output p1y,
    output p2y
);
    // Implementing 7420 (Two 4-input NAND gates)
    // Gate 1 (p1y): NAND(p1a, p1b, p1c, p1d)
    assign p1y = ~(p1a & p1b & p1c & p1d);
    // Gate 2 (p2y): NAND(p2a, p2b, p2c, p2d)
    assign p2y = ~(p2a & p2b & p2c & p2d);
endmodule

module stimulus_gen (
    input clk,
    output reg p1a, p1b, p1c, p1d,
    output reg p2a, p2b, p2c, p2d,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
    

    initial begin
        int count; count = 0;
        {p1a,p1b,p1c,p1d} <= 4'h0;        
        {p2a,p2b,p2c,p2d} <= 4'h0;        
        wavedrom_start("Two NAND gates");
        repeat(20) @(posedge clk) begin
            {p1a,p1b,p1c,p1d} <= count;        
            {p2a,p2b,p2c,p2d} <= count+1;        
            count = count + 1;
        end
        wavedrom_stop();

        repeat(200) @(posedge clk,negedge clk) begin
            {p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d} <= $random;
        end
        
        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_p1y;
        int errortime_p1y;
        int errors_p2y;
        int errortime_p2y;

        int clocks;
        // Store state at first error
        logic [7:0] inputs_at_error;
        logic p1y_ref_at_error;
        logic p2y_ref_at_error;
        logic p1y_dut_at_error;
        logic p2y_dut_at_error;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic p1a;
    logic p1b;
    logic p1c;
    logic p1d;
    logic p2a;
    logic p2b;
    logic p2c;
    logic p2d;
    logic p1y_ref;
    logic p1y_dut;
    logic p2y_ref;
    logic p2y_dut;

    // Storage for state capture at first error
    reg [7:0] captured_inputs;
    reg p1y_ref_captured;
    reg p2y_ref_captured;
    reg p1y_dut_captured;
    reg p2y_dut_captured;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen.stim1.clk, tb_mismatch ,p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d,p1y_ref,p1y_dut,p2y_ref,p2y_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .p1a,
        .p1b,
        .p1c,
        .p1d,
        .p2a,
        .p2b,
        .p2c,
        .p2d );
    RefModule good1 (
        .p1a,
        .p1b,
        .p1c,
        .p1d,
        .p2a,
        .p2b,
        .p2c,
        .p2d,
        .p1y(p1y_ref),
        .p2y(p2y_ref) );
        
    TopModule top_module1 (
        .p1a,
        .p1b,
        .p1c,
        .p1d,
        .p2a,
        .p2b,
        .p2c,
        .p2d,
        .p1y(p1y_dut),
        .p2y(p2y_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Verification: Match if reference equals DUT
    assign tb_match = ( { p1y_ref, p2y_ref } === { p1y_dut, p2y_dut } );
    
    // Monitoring and Error Tracking
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Check for total mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Capture inputs and signals at the exact moment of first error detection
                captured_inputs = {p1a, p1b, p1c, p1d, p2a, p2b, p2c, p2d};
                p1y_ref_captured = p1y_ref;
                p2y_ref_captured = p2y_ref;
                p1y_dut_captured = p1y_dut;
                p2y_dut_captured = p2y_dut;
                $display("
====================================================");
                $display("--- FIRST MISMATCH DETECTED AT TIME %0d ps ---", $time);
                // Display inputs in HEX and BIN (Width <= 64 bits)
                $display("Inputs: {HEX} = %h, {BIN} = %b", captured_inputs, captured_inputs);
                // Display expected and actual outputs
                $display("Expected Outputs (Ref): p1y=%b, p2y=%b", p1y_ref, p2y_ref);
                $display("Actual Outputs (DUT):  p1y=%b, p2y=%b", p1y_dut, p2y_dut);
                $display("====================================================");
                
            stats1.errors++;
            
            // Individual Output Mismatch Tracking
            if (p1y_ref !== p1y_dut) begin
                if (stats1.errors_p1y == 0) stats1.errortime_p1y = $time;
                stats1.errors_p1y++;
            end
            if (p2y_ref !== p2y_dut) begin
                if (stats1.errors_p2y == 0) stats1.errortime_p2y = $time;
                stats1.errors_p2y++;
            end
        end
    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    
    // Final reporting block
    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            // Display detailed info if errors occurred (using captured state from first error)
            $display("
--- FIRST ERROR STATE DETAILS ---");
            $display("Inputs: {HEX} = %h, {BIN} = %b", captured_inputs, captured_inputs);
            $display("Expected Outputs (Ref): p1y=%b, p2y=%b", p1y_ref_captured, p2y_ref_captured);
            $display("Actual Outputs (DUT):  p1y=%b, p2y=%b", p1y_dut_captured, p2y_dut_captured);
            $display("---------------------------------");
        end
        
        // Retaining original per-output hints for completeness
        if (stats1.errors_p1y > 0) $display("Hint: Output 'p1y' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_p1y, stats1.errortime_p1y);
        else $display("Hint: Output 'p1y' has no mismatches.");
        if (stats1.errors_p2y > 0) $display("Hint: Output 'p2y' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_p2y, stats1.errortime_p2y);
        else $display("Hint: Output 'p2y' has no mismatches.");
        
        $display("
Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule