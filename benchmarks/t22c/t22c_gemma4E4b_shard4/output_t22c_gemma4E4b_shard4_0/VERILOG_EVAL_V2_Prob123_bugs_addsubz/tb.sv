`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- DUT Definition (Fixed Version) ---
module TopModule_Fixed (
    input logic do_sub,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] out,
    output logic result_is_zero
);

    // Combinational logic to perform addition or subtraction
    always @(*) begin
        case (do_sub)
            0: out = a + b;
            1: out = a - b;
        endcase

        // FIX: The zero flag must check if the entire result vector is zero.
        if (out == 8'b0)
            result_is_zero = 1;
        else
            result_is_zero = 0;
    end

endmodule

// --- Stimulus Generator (Copied from Golden TB) ---
module stimulus_gen (
    input clk,
    output logic do_sub,
    output logic [7:0] a, b,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask


    initial begin
        {a, b} <= 16'haabb;
        do_sub <= 0;
        @(negedge clk) wavedrom_start("");
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 1;
            @(posedge clk, negedge clk) do_sub <= 1;
            
            @(posedge clk, negedge clk) {a, b} <= 16'h0303; do_sub <= 1'b0;
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 1;
            @(posedge clk, negedge clk) {a, b} <= 16'h0304; do_sub <= 1'b0;
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 1;
            @(posedge clk, negedge clk) {a, b} <= 16'hfd03; do_sub <= 1'b0;
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 1;
            @(posedge clk, negedge clk) {a, b} <= 16'hfd04; do_sub <= 1'b0;
            @(posedge clk, negedge clk) do_sub <= 0;
            @(posedge clk, negedge clk) do_sub <= 1;
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk) begin
            {a,b, do_sub} <= $urandom;
        end
            
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int errors_result_is_zero;
        int errortime_result_is_zero;

        int clocks;
    } stats;
    
    // Structure to hold details of the FIRST mismatch
    typedef struct packed {
        time'time first_err_time;
        logic do_sub_err;
        logic [7:0] a_err;
        logic [7:0] b_err;
        logic [7:0] out_ref_err;
        logic [7:0] out_dut_err;
        logic result_is_zero_ref_err;
        logic result_is_zero_dut_err;
    } first_mismatch_info;
    
    stats stats1;
    first_mismatch_info mismatch_details;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic do_sub;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] out_ref;
    logic [7:0] out_dut;
    logic result_is_zero_ref;
    logic result_is_zero_dut;

    // Signal to track if the very first error has been logged
    logic first_error_logged = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,do_sub,a,b,out_ref,out_dut,result_is_zero_ref,result_is_zero_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate Stimulus Generator
    stimulus_gen stim1 (
        .clk,
        .do_sub,
        .a,
        .b,
        .wavedrom_title,
        .wavedrom_enable,
        .tb_match
    );
    
    // Instantiate Reference Model (using the original structure)
    // NOTE: RefModule must be defined elsewhere or assumed to exist.
    RefModule good1 (
        .do_sub,
        .a,
        .b,
        .out(out_ref),
        .result_is_zero(result_is_zero_ref) );
        
    // Instantiate DUT (Using the fixed module)
    TopModule_Fixed top_module1 (
        .do_sub,
        .a,
        .b,
        .out(out_dut),
        .result_is_zero(result_is_zero_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask


    // Helper task to display signals in HEX and BIN if width <= 64
    task display_signals(string label, logic signal_val, int width);
        if (width <= 64) begin
            $display("\n--- %s Signal Details (Width: %0d) ---", label, width);
            $display("  HEX: 0x%h", signal_val);
            $display("  BIN: %b", signal_val);
        end
    endtask

    task display_signals_vector(string label, logic [7:0] signal_val);
        // Since width is 8 <= 64, we display both
        $display("\n--- %s Signal Details (Width: 8) ---", label);
        $display("  HEX: 0x%h", signal_val);
        $display("  BIN: %b", signal_val);
    endtask

    
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;

        // Check for Mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time; // Record time of first error
                mismatch_details.first_err_time = $time;
            end
            stats1.errors++;
        end

            // Check specific output errors and log details if this is the first error
            
            // Check 'out'
            if (stats1.errors_out == 0) begin
                stats1.errortime_out = $time; // Record time of first 'out' error
                mismatch_details.out_ref_err = out_ref;
                mismatch_details.out_dut_err = out_dut;
            end
            if (out_ref !== out_dut) begin
                stats1.errors_out = stats1.errors_out + 1'b1;
            end
            
            // Check 'result_is_zero'
            if (stats1.errors_result_is_zero == 0) begin
                stats1.errortime_result_is_zero = $time; // Record time of first 'zero' error
                mismatch_details.result_is_zero_ref_err = result_is_zero_ref;
                mismatch_details.result_is_zero_dut_err = result_is_zero_dut;
            end
            if (result_is_zero_ref !== result_is_zero_dut) begin
                stats1.errors_result_is_zero = stats1.errors_result_is_zero + 1'b1;
            end
        end
        
        // Log inputs whenever an error occurs for the first time
        if (!tb_match && stats1.errors == 1 && !first_error_logged) begin
            mismatch_details.do_sub_err = do_sub;
            mismatch_details.a_err = a;
            mismatch_details.b_err = b;
            
            // Display detailed error information for the FIRST mismatch
            $display("\n================================================================================\n");
            $display("*** FIRST MISMATCH DETECTED AT TIME %0d ps ***", $time);
            $display("================================================================================\n");
            $display("INPUT SIGNALS:");
            $display("  do_sub: %b", mismatch_details.do_sub_err);
            display_signals_vector("  Input a", mismatch_details.a_err);
            display_signals_vector("  Input b", mismatch_details.b_err);
            
            $display("EXPECTED OUTPUTS (REFERENCE):");
            display_signals_vector("  Out_ref", mismatch_details.out_ref_err);
            $display("  Result_is_zero_ref: %b", mismatch_details.result_is_zero_ref_err);
            
            $display("ACTUAL OUTPUTS (DUT):");
            display_signals_vector("  Out_dut", mismatch_details.out_dut_err);
            $display("  Result_is_zero_dut: %b", mismatch_details.result_is_zero_dut_err);
            $display("================================================================================\n");
            
            first_error_logged = 1;
        end
    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      if (stats1.errors == 0) begin
          $display("SIMULATION PASSED");
      end else begin
          $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
      end
      $finish();
    end

endmodule