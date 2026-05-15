`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Interface definitions based on golden_testbench usage
module stimulus_gen (
    input logic clk,
    input logic in,
    input logic reset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input logic tb_match
);
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

    // Add two ports to module stimulus_gen:
    //    output [511:0] wavedrom_title
    //    output reg wavedrom_enable

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
    

    initial begin
        reset <= 1;
        in <= 0;
        @(posedge clk) reset <= 0; in <= 1;
        @(posedge clk) in <= 0;
        @(posedge clk) in <= 1;
        wavedrom_start();
            @(posedge clk) in <= 0;
            @(posedge clk) in <= 1;
            @(posedge clk);
            @(negedge clk) reset <= 1;
            @(posedge clk) reset <= 0;
            @(posedge clk) in <= 1;
            @(posedge clk) in <= 1;
            @(posedge clk) in <= 0;
            @(posedge clk) in <= 1;
            @(posedge clk) in <= 0;
            @(posedge clk) in <= 1;
            @(posedge clk) in <= 1;
            @(posedge clk) in <= 1;
        @(negedge clk);
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
        end

        #1 $finish;
    end
    
endmodule

module RefModule (input logic clk, input logic in, input logic reset, output logic out);
    // Dummy implementation for compilation, assuming it behaves correctly
    assign out = in;
endmodule

// TopModule implementation (as per specification)
module TopModule (input logic clk, input logic reset, input logic in, output logic out);
    // State Definition (A=00, B=01, C=10, D=11)
    typedef enum logic [1:0] {A, B, C, D} state_t;

    state_t current_state, next_state;
    logic output_reg;
    
    // State Register Logic (Synchronous Reset)
    always_ff @(posedge clk)
    begin
        if (reset) begin
            current_state <= A; // Synchronous active high reset
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next State Logic (Combinational)
    always_comb begin
        next_state = current_state;
        case (current_state) 
            A: next_state = in ? B : A;
            B: next_state = in ? C : B;
            C: next_state = in ? D : A;
            D: next_state = in ? C : B;
            default: next_state = A; // Safety default
        endcase
    end
    
    // Output Logic (Moore Machine - Combinational based on current_state)
    always_comb begin
        case (current_state) 
            A: output_reg = 1'b0;
            B: output_reg = 1'b0;
            C: output_reg = 1'b0;
            D: output_reg = 1'b1;
            default: output_reg = 1'b0; // Safety default
        endcase
    end
    
    // Output assignment
    assign out = output_reg;
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
    
    // Signals from stimulus_gen
    logic[511:0] wavedrom_title;
    logic wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic in;
    logic reset;
    logic out_ref;
    logic out_dut;

    // Signals captured for detailed mismatch report
    logic [511:0] captured_in_sig = 0;
    logic captured_reset_sig = 0;
    logic captured_out_ref_sig = 0;
    logic captured_out_dut_sig = 0;
    
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen, tb);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Stimulus Generator Instantiation
    stimulus_gen stim1 (
        .clk, 
        .in, 
        .reset,
        .wavedrom_title, 
        .wavedrom_enable,
        .tb_match 
    );
    
    // Reference Module Instantiation
    RefModule good1 (
        .clk,
        .in,
        .reset,
        .out(out_ref) );
    
    // DUT Instantiation
    TopModule top_module1 (
        .clk,
        .in,
        .reset,
        .out(out_dut) );
    
    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask
    
    // Main Simulation Loop
    always @(posedge clk, negedge clk) begin
        
        stats1.clocks++;
        
        // Capture current state for potential display if mismatch happens
        captured_in_sig <= in;
        captured_reset_sig <= reset;
        captured_out_ref_sig <= out_ref;
        captured_out_dut_sig <= out_dut;
        
        // 1. Check overall match (Used for general error counting)
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                
                $display("\n============================================================================",
                );
                $display("!!! FIRST MISMATCH DETECTED (Overall Match) !!!");
                $display("Time: %0d ps", $time);
                $display("--- Input Signals ---");
                $display("clk: %0b", clk);
                $display("in: %0b", in);
                $display("reset: %0b", reset);
                $display("--- Output Signals ---");
                // Displaying Ref (Expected) and DUT (Actual) for the first general mismatch
                $display("Reference Out (Expected): %b (0x%h) | Binary: %b", captured_out_ref_sig, captured_out_ref_sig, captured_out_ref_sig);
                $display("DUT Output (Actual): %b (0x%h) | Binary: %b", captured_out_dut_sig, captured_out_dut_sig, captured_out_dut_sig);
                $display("============================================================================\n");
            end
            stats1.errors++;
        end
        
        // 2. Check specific output mismatch (Used for stats1.errors_out)
        if (out_ref !== out_dut)
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out+1'b1; 
        end
        end
        
    end
    
    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    // Final reporting logic
    final begin
        if (stats1.errors_out == 0) 
            $display("SIMULATION PASSED");
        else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end
        
        // Original final block structure maintained for logging
        if (stats1.errors_out) $display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out, stats1.errortime_out);
        else $display("Hint: Output 'out' has no mismatches.");
        
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
endmodule