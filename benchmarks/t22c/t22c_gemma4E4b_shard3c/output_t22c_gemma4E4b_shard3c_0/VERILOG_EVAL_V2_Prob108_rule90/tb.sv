`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Placeholder for modules referenced in the golden testbench that are not defined here
module stimulus_gen (
    input clk,
    output reg load,
    output reg[511:0] data,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);
    // Placeholder implementation
endmodule

module RefModule (
    input logic clk,
    input logic load,
    input logic [511:0] data,
    output logic [511:0] q
);
    // Placeholder implementation
endmodule

// The DUT interface matches the specification
module TopModule (
    input logic clk,
    input logic load,
    input logic [511:0] data,
    output logic [511:0] q
);
    // DUT implementation placeholder (assuming it's linked externally)
endmodule

// --- Testbench Implementation ---
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;

        int clocks;
    } stats;
    
    stats stats1;
    
    
    logic [511:0] wavedrom_title;
    logic wavedrom_enable;
    int wavedrom_hide_after_time;
    
    logic clk=0;
    initial forever
        #5 clk = ~clk;

    logic load;
    logic [511:0] data;
    logic [511:0] q_ref;
    logic [511:0] q_dut;

    // Task to display detailed error information (Improved display formatting)
    task display_first_mismatch;
        input int time_of_error;
        input logic [511:0] data_val;
        input logic load_val;
        input logic [511:0] q_ref_val;
        input logic [511:0] q_dut_val;
        
        // Required formatting: Display input/output signals
        $display("
=============================================================");
        $display("FIRST MISMATCH DETECTED AT TIME: %0d ps", time_of_error);
        $display("---------------------------------------------------------------");
        $display("INPUTS:");
        $display("  clk: %b (Not actively displayed per spec, time-based)", clk);
        $display("  load: %b", load_val);
        $display("  data (HEX): %h", data_val);
        // Display BIN format if width <= 64
        $display("  data (BIN - First 64 bits): %b", data_val[63:0]);
        $display("---------------------------------------------------------------");
        $display("OUTPUTS:");
        $display("  Expected q_ref (HEX): %h", q_ref_val);
        $display("  DUT q_dut (HEX): %h", q_dut_val);
        // Display BIN format if width <= 64
        $display("  DUT q_dut (BIN - First 64 bits): %b", q_dut_val[63:0]);
        $display("=============================================================");
    endtask
    
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,clk,load,data,q_ref,q_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .load,
        .data,
        .wavedrom_title,
        .wavedrom_enable 
    );
    
    // RefModule instantiation
    RefModule good1 (
        .clk,
        .load,
        .data,
        .q(q_ref) 
    );
        
    // TopModule DUT instantiation
    TopModule top_module1 (
        .clk,
        .load,
        .data,
        .q(q_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Task to handle error logging when the first mismatch occurs
    task handle_error;
        input int current_time;
        input logic [511:0] current_data;
        input logic current_load;
        input logic [511:0] current_q_ref;
        input logic [511:0] current_q_dut;
        
        if (stats1.errors == 0) begin
            // This is the first error
            stats1.errortime = current_time;
            display_first_mismatch(current_time, current_data, current_load, current_q_ref, current_q_dut);
        end
        stats1.errors++;
    endtask
    
    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
        $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    
    // Verification Logic
    // The original golden TB used: assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
    // Since the TB structure was changed, we adopt the simpler match used in the provided 'previous_tb' structure for consistency, while acknowledging the original check.
    // We must follow the structure that led to the successful template:
    assign tb_match = ( q_ref === q_dut );
    
    // Clocked verification process
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        if (!tb_match) begin
            // Check for mismatch against the actual expected state (Q_ref)
            handle_error($time, data, load, q_ref, q_dut);
        end

        // Original secondary check (kept for functional preservation)
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1; 
        end

    end

    // Add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    // Original stimulus generation sequence (must be maintained)
    initial begin
        data <= 0;
        data[0] <= 1'b1;
        load <= 1;
        @(posedge clk); wavedrom_start("Sierpi\u0171ski triangle: See Hint.");
        @(posedge clk);
        @(posedge clk);
        load <= 0;
        repeat(10) @(posedge clk) ;        
        wavedrom_stop();

        
        data <= 0;
        data[256] <= 1'b1;
        load <= 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk) begin
        end
        data <= 512'h1000000000000001;
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk) begin
        end

        data <= $random;
        load <= 1;
        @(posedge clk);
        load <= 0;
        repeat(1000) @(posedge clk) begin
        end

        data <= 0;
        load <= 1;
        repeat(20) @(posedge clk);
        repeat(2) @(posedge clk) data <= data + 2;
        @(posedge clk) begin 
            load <= 0;
            data <= data + 1;
        end
        repeat(20) @(posedge clk) data <= data + 1;
        repeat(500) @(posedge clk) begin
        end

        #1 $finish;
    end

endmodule