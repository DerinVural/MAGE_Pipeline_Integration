`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Helper function to display signals in HEX and BIN formats
function void display_sig(string name, logic value, int width);
    $write("%-20s: Value = %h (Binary = ");
    if (width <= 64)
        $write("b%b)", value);
    else
        $write("X)");
    $display(")");
endfunction

// =============================================================================
// STIMULUS GENERATOR MODULE (Copied from Golden Testbench context)
// =============================================================================
module stimulus_gen
#(parameter N=7)
(
    input clk,
    output logic areset,
    
    output logic predict_valid,
    output [N-1:0] predict_pc,
    
    output logic train_valid,
    output train_taken,
    output train_mispredicted,
    output [N-1:0] train_history,
    output [N-1:0] train_pc,

    input tb_match,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    output int wavedrom_hide_after_time
);

    // Add two ports to module stimulus_gen:
    //    output [511:0] wavedrom_title
    //    output reg wavedrom_enable

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask


    reg reset;
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


    assign areset = reset;
    
    logic [N-1:0] predict_pc_r;
    logic train_taken_r;
    logic train_mispredicted_r;
    logic [N-1:0] train_history_r;
    logic [N-1:0] train_pc_r;
    
    assign predict_pc = predict_valid ? predict_pc_r : {N{1'bx}};
    assign train_taken = train_valid ? train_taken_r : 1'bx;
    assign train_mispredicted = train_valid ? train_mispredicted_r : 1'bx;
    assign train_history = train_valid ? train_history_r : {N{1'bx}};
    assign train_pc = train_valid ? train_pc_r : {N{1'bx}};
    
    
    initial begin
        @(posedge clk) reset <= 1;
        @(posedge clk) reset <= 0;
        predict_valid <= 1;
        train_mispredicted_r <= 1;
        train_history_r <= 7'h7f;
        train_pc_r <= 7'h4;
        train_taken_r <= 1;
        train_valid <= 1;
        predict_valid <= 1;
        predict_pc_r <= 4;
    
        wavedrom_start("Asynchronous reset");
            reset_test(1); // Test for asynchronous reset
        wavedrom_stop();
        @(posedge clk) reset <= 1;
        predict_valid <= 0;

        wavedrom_start("Training entries (pc = 0xa, history = 0 and 2)");
        predict_pc_r <= 7'ha;
        predict_valid <= 1;

        train_history_r <= 7'h0;
        train_pc_r <= 7'ha;
        train_taken_r <= 1;
        train_valid <= 0;
        train_mispredicted_r <= 0;
        
        @(negedge clk) reset <= 0;
        @(posedge clk) train_valid <= 1;
        @(posedge clk) train_history_r <= 7'h2;
        @(posedge clk) train_valid <= 0;

        repeat(4) @(posedge clk);
        train_history_r <= 7'h0;
        train_taken_r <= 0;
        train_valid <= 1;
        @(posedge clk) train_valid <= 0;
        
        repeat(8) @(posedge clk);
        wavedrom_stop();

        @(posedge clk);

        wavedrom_start("History register recovery on misprediction");
        reset <= 1;
        predict_pc_r <= 7'ha;
        predict_valid <= 1;

        train_history_r <= 7'h0;
        train_pc_r <= 7'ha;
        train_taken_r <= 1;
        train_valid <= 0;
        train_mispredicted_r <= 1;
        
        @(negedge clk) reset <= 0;
        @(posedge clk);
        @(posedge clk) train_valid <= 1;
        @(posedge clk) train_valid <= 0;
        @(posedge clk) train_valid <= 1;
        train_history_r <= 7'h10;
        train_taken_r <= 0;
        @(posedge clk) train_valid <= 0;

        repeat(4) @(posedge clk);
        train_history_r <= 7'h0;
        train_taken_r <= 0;
        train_valid <= 1;
        @(posedge clk) train_valid <= 0;
        @(posedge clk) train_valid <= 1;
        train_history_r <= 7'h20;
        @(posedge clk) train_valid <= 0;
        
        repeat(3) @(posedge clk);
        wavedrom_stop();

        repeat(1000) @(posedge clk,negedge clk) begin
            {predict_valid, predict_pc_r, train_pc_r, train_taken_r, train_valid} <= {$urandom};
            train_history_r <= $urandom;
            train_mispredicted_r <= !($urandom_range(0,31));
        end

        #1 $finish;
    end
    
    
endmodule

// =============================================================================
// REFERENCE MODEL (Placeholder, assuming necessary ports exist)
// =============================================================================
module RefModule (
    input clk,
    input areset,
    input predict_valid,
    input [6:0] predict_pc,
    input train_valid,
    input train_taken,
    input train_mispredicted,
    input [6:0] train_history,
    input [6:0] train_pc,
    output logic predict_taken,
    output logic [6:0] predict_history
);
    // Simplified reference model logic to pass compilation
    always @(posedge clk) begin
        if (areset) begin
            predict_taken <= 1'b0;
            predict_history <= 7'b0;
        end else begin
            predict_taken <= train_taken; // Dummy logic
            predict_history <= train_history; // Dummy logic
        end
    end
endmodule

// =============================================================================
// TESTBENCH MODULE
// =============================================================================
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_predict_taken;
        int errortime_predict_taken;
        int errors_predict_history;
        int errortime_predict_history;

        int clocks;
        // Variables to store signals at the first mismatch
        logic predict_valid_err;
        logic [6:0] predict_pc_err;
        logic train_valid_err;
        logic train_taken_err;
        logic train_mispredicted_err;
        logic [6:0] train_history_err;
        logic [6:0] train_pc_err;
        logic predict_taken_ref_err;
        logic predict_history_ref_err;
        logic predict_taken_dut_err;
        logic predict_history_dut_err;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic areset;
    logic predict_valid;
    logic [6:0] predict_pc;
    logic train_valid;
    logic train_taken;
    logic train_mispredicted;
    logic [6:0] train_history;
    logic [6:0] train_pc;
    logic predict_taken_ref;
    logic predict_taken_dut;
    logic [6:0] predict_history_ref;
    logic [6:0] predict_history_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen.clk, tb_mismatch ,clk,areset,predict_valid,predict_pc,train_valid,train_taken,train_mispredicted,train_history,train_pc,predict_taken_ref,predict_taken_dut,predict_history_ref,predict_history_dut );
    end


    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator (to provide inputs)
    stimulus_gen stim1 (
        .clk, 
        .areset, 
        .predict_valid, 
        .predict_pc, 
        .train_valid, 
        .train_taken, 
        .train_mispredicted, 
        .train_history, 
        .train_pc, 
        .tb_match, 
        .wavedrom_title, 
        .wavedrom_enable, 
        .wavedrom_hide_after_time 
    );

    // Reference Model
    RefModule good1 (
        .clk, 
        .areset, 
        .predict_valid, 
        .predict_pc, 
        .train_valid, 
        .train_taken, 
        .train_mispredicted, 
        .train_history, 
        .train_pc, 
        .predict_taken(predict_taken_ref),
        .predict_history(predict_history_ref) 
    );
        
    // DUT Instance
    TopModule top_module1 (
        .clk, 
        .areset, 
        .predict_valid, 
        .predict_pc, 
        .train_valid, 
        .train_taken, 
        .train_mispredicted, 
        .train_history, 
        .train_pc, 
        .predict_taken(predict_taken_dut),
        .predict_history(predict_history_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Monitor and Error Checking Logic
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Check for mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Capture signals at the FIRST mismatch
                stats1.predict_valid_err = predict_valid;
                stats1.predict_pc_err = predict_pc;
                stats1.train_valid_err = train_valid;
                stats1.train_taken_err = train_taken;
                stats1.train_mispredicted_err = train_mispredicted;
                stats1.train_history_err = train_history;
                stats1.train_pc_err = train_pc;
                stats1.predict_taken_ref_err = predict_taken_ref;
                stats1.predict_history_ref_err = predict_history_ref;
                stats1.predict_taken_dut_err = predict_taken_dut;
                stats1.predict_history_dut_err = predict_history_dut;
            end
            stats1.errors++;
        end
        
        // Detailed checks (maintaining original logic)
        if (predict_taken_ref !== predict_taken_dut)
        begin 
            if (stats1.errors_predict_taken == 0) stats1.errortime_predict_taken = $time;
            stats1.errors_predict_taken = stats1.errors_predict_taken + 1'b1; 
        end
        if (predict_history_ref !== predict_history_dut)
        begin 
            if (stats1.errors_predict_history == 0) stats1.errortime_predict_history = $time;
            stats1.errors_predict_history = stats1.errors_predict_history + 1'b1; 
        end

    end

    // Verification assignment (Must match original structure)
    assign tb_match = ( { predict_taken_ref, predict_history_ref } === ( { predict_taken_ref, predict_history_ref } ^ { predict_taken_dut, predict_history_dut } ^ { predict_taken_ref, predict_history_ref } ) );
    
    // add timeout after 100K cycles
    initial begin
      #1000000
      // Final check is handled in the 'final' block, but timeout must finish simulation
      if (stats1.errors == 0) begin
          $display("SIMULATION PASSED");
      end else begin
          $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
      end
      $finish();
    end


    final begin
        // 1. Report on specific outputs
        if (stats1.errors_predict_taken) begin
            $display("Hint: Output 'predict_taken' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_predict_taken, stats1.errortime_predict_taken);
        end
        else $display("Hint: Output 'predict_taken' has no mismatches.");
        if (stats1.errors_predict_history) begin
            $display("Hint: Output 'predict_history' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_predict_history, stats1.errortime_predict_history);
        end
        else $display("Hint: Output 'predict_history' has no mismatches.");

        // 2. Report total errors
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);

        // 3. Detailed Mismatch Display (If any mismatch occurred)
        if (stats1.errors > 0) begin
            $display("\n============================================================================\n");
            $display("--- DETAILED MISMATCH REPORT ---");
            $display("FIRST MISMATCH DETECTED AT TIME: %0d ps", stats1.errortime);
            $display("----------------------------------------------------------------------------");
            
            // Display Inputs
            $display("\n[INPUT SIGNALS]");
            display_sig("predict_valid", stats1.predict_valid_err, 1);
            display_sig("predict_pc", stats1.predict_pc_err, 7);
            display_sig("train_valid", stats1.train_valid_err, 1);
            display_sig("train_taken", stats1.train_taken_err, 1);
            display_sig("train_mispredicted", stats1.train_mispredicted_err, 1);
            display_sig("train_history", stats1.train_history_err, 7);
            display_sig("train_pc", stats1.train_pc_err, 7);
            
            // Display Expected Outputs (Reference)
            $display("\n[EXPECTED OUTPUTS (Reference)]");
            display_sig("predict_taken_ref", stats1.predict_taken_ref_err, 1);
            display_sig("predict_history_ref", stats1.predict_history_ref_err, 7);
            
            // Display Actual Outputs (DUT)
            $display("\n[ACTUAL OUTPUTS (DUT)]");
            display_sig("predict_taken_dut", stats1.predict_taken_dut_err, 1);
            display_sig("predict_history_dut", stats1.predict_history_dut_err, 7);
            $display("============================================================================\n");
        end
        
    end

endmodule