`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Module implementing the specification (2-input NOR gate)
module TopModule (
    input logic in1,
    input logic in2,
    output logic out
);
    // Implementation of 2-input NOR gate: out = NOT (in1 OR in2)
    assign out = ~(in1 | in2);
endmodule

// Stimulus Generator (from golden testbench)
module stimulus_gen (
    input clk,
    output logic in1, in2
);
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            {in1, in2} <= $random;
        end
        
        #1 $finish;
    end
endmodule

// Reference Module (Assumed structure, necessary for testbench functionality)
module RefModule (
    input logic in1,
    input logic in2,
    output logic out
);
    // Reference model should implement NOR gate as well for correctness
    assign out = ~(in1 | in2);
endmodule

// Testbench
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    
    stats stats1;
    
    // Signals required for dumping and tracking
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic in1;
    logic in2;
    logic out_ref;
    logic out_dut;

    // Variables to capture the state at the first mismatch
    logic [1:0] mismatch_inputs_state; // {in1, in2}
    logic [1:0] mismatch_outputs_state; // {out_ref, out_dut}

    initial begin 
        $dumpfile("wave.vcd");
        // Dump vars for tb, including the state variables
        $dumpvars(1, tb, in1, in2, out_ref, out_dut, stats1, mismatch_inputs_state, mismatch_outputs_state);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* , 
        .in1,
        .in2 );
    RefModule good1 (
        .in1,
        .in2,
        .out(out_ref) );
        
    TopModule top_module1 (
        .in1,
        .in2,
        .out(out_dut) );

    // Task definition (moved outside the scope where it caused errors)
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    bit strobe = 0;

    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Clocked logic for counting and state capture
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        // Error counting logic (General mismatch)
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // Error counting for output mismatch (stats1.errors_out)
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1'b1; 
        end
        
        // Capture state on first general mismatch
        if (!tb_match && stats1.errors == 1) begin
            mismatch_inputs_state = {in1, in2};
            mismatch_outputs_state = {out_ref, out_dut};
        end

    end

    // Add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    // Final Reporting Logic (Improved)
    initial begin
        @(negedge clk);
        #1; // Wait slightly for all logic to settle after the last clock edge
        
        if (stats1.errors_out == 0)
        begin
            $display("SIMULATION PASSED");
        end
        else begin
            // Failure reporting format required
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
            
            // 1. Display input signals at first output mismatch time
            $display("
--- FIRST MISMATCH DETAILS (Triggered by Output Mismatch) ---");
            $display("Time: %0d ps", stats1.errortime_out);
            
            // Display inputs captured at the first general mismatch
            $display("Inputs: in1=%b, in2=%b", mismatch_inputs_state[0], mismatch_inputs_state[1]);
            
            // 2. Display output signals at first output mismatch time
            $display("Outputs: Ref (Expected)=%b, DUT (Actual)=%b", mismatch_outputs_state[0], mismatch_outputs_state[1]);
            
            // 3. Display expected output
            $display("Expected Output (out_ref): %b", mismatch_outputs_state[0]);
        end
            
        // Original summary print (kept for reference/completeness)
        $display("
--- Summary ---");
        $display("Total mismatched samples (tb_match): %1d out of %1d samples", stats1.errors, stats1.clocks);
    end

endmodule