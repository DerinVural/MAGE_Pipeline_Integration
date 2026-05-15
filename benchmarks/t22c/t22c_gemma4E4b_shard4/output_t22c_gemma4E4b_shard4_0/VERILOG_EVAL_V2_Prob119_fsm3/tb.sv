`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// ==================================================================================
// DUT Interface (Matches requirements and golden testbench usage)
// ==================================================================================
module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

// State Encoding (2 bits required for 4 states: A, B, C, D)
localparam [1:0] STATE_A = 2'b00;
localparam [1:0] STATE_B = 2'b01;
localparam [1:0] STATE_C = 2'b10;
localparam [1:0] STATE_D = 2'b11;

// State register
logic [1:0] current_state;
logic [1:0] next_state;

// State Register Logic (Asynchronous Reset)
always @(posedge clk or posedge areset) begin
    if (areset)
        current_state <= STATE_A; // Reset to State A
    else
        current_state <= next_state;
end

// Next State and Output Logic (Combinational)
always @(*)
begin
    // Default assignments to prevent unintended latch inference
    next_state = current_state;
    out = 1'b0; // Default output (Moore FSM)

    case (current_state)
        STATE_A:
        begin
            if (in == 0) 
                next_state = STATE_A;
            else 
                next_state = STATE_B;
            out = 1'b0;
        end
        
        STATE_B:
        begin
            if (in == 0) 
                next_state = STATE_C;
            else 
                next_state = STATE_B;
            out = 1'b0;
        end
        
        STATE_C:
        begin
            if (in == 0) 
                next_state = STATE_A;
            else 
                next_state = STATE_D;
            out = 1'b0;
        end
        
        STATE_D:
        begin
            if (in == 0) 
                next_state = STATE_C;
            else 
                next_state = STATE_B;
            out = 1'b1; // Output is 1 only in State D
        end

        default: begin
            next_state = STATE_A; // Should not happen
            out = 1'b0;
        end
    endcase
end

// Initialization: Ensure state is not X before the first clock cycle/reset sequence
initial begin
    current_state = STATE_A;
end
endmodule

// ==================================================================================
// Stimulus Generator (Copied from Golden Testbench)
// ==================================================================================
module stimulus_gen (
    input clk,
    output logic in,
    output logic areset,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;
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
            @(posedge clk) in <= 0;
            end
        wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) begin
            in <= $random;
            reset <= !($random & 31);
        end

        #1 $finish;
    end
    
endmodule

// ==================================================================================
// Reference Module (For golden comparison)
// ==================================================================================
module RefModule (
    input clk,
    input in,
    input areset,
    output logic out
);

    // Reference Implementation (Must match TopModule behavior for golden test)
    typedef enum logic [1:0] {STATE_A, STATE_B, STATE_C, STATE_D} state_t;
    state_t current_state, next_state;
    logic fsm_output;

    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_A; // Asynchronous reset to A
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state) 
            STATE_A: next_state = in ? STATE_B : STATE_A;
            STATE_B: next_state = in ? STATE_B : STATE_C;
            STATE_C: next_state = in ? STATE_D : STATE_A;
            STATE_D: next_state = in ? STATE_B : STATE_C;
            default: next_state = STATE_A;
        endcase
    end

    always_comb begin
        case (current_state) 
            STATE_A: fsm_output = 1'b0;
            STATE_B: fsm_output = 1'b0;
            STATE_C: fsm_output = 1'b0;
            STATE_D: fsm_output = 1'b1;
            default: fsm_output = 1'b0;
        endcase
    end

    assign out = fsm_output;
endmodule

// ==================================================================================
// Testbench (Improved Golden Testbench)
// ==================================================================================
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;

        int clocks;
        // New fields to capture first mismatch details
        logic [511:0] in_at_mismatch;
        logic areset_at_mismatch;
        logic out_ref_at_mismatch;
        logic out_dut_at_mismatch;
    } stats;
    
    stats stats1;
    
    // Signal declarations
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic in;
    logic areset;
    logic out_ref;
    logic out_dut;

    // Signal to capture state at first mismatch (for detailed display)
    logic [511:0] capture_in_sig;
    logic capture_areset_sig;
    logic capture_out_ref_sig;
    logic capture_out_dut_sig;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, in, areset, out_ref, out_dut, capture_in_sig, capture_areset_sig, capture_out_ref_sig, capture_out_dut_sig );
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    // Instantiate Stimulus Generator
    stimulus_gen stim1 (
        .clk, 
        .*, 
        .in, 
        .areset );
    
    // Instantiate Reference Module
    RefModule good1 (
        .clk,
        .in,
        .areset,
        .out(out_ref) );
        
    // Instantiate DUT
    TopModule top_module1 (
        .clk,
        .areset,
        .in,
        .out(out_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    final begin
        // Enhanced reporting logic
        if (stats1.errors > 0 || stats1.errors_out > 0) begin
            // Calculate total mismatches based on original error counting logic
            int total_mismatches = stats1.errors + stats1.errors_out;
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", total_mismatches, stats1.errortime);
            
            // Display first mismatch details (using the captured state)
            $display("
--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
            
            // Display Inputs
            $display("Inputs:");
            // CLK is usually not displayed in this manner as it's the clocking source
            $display("  areset: %b (HEX: %h)", stats1.areset_at_mismatch, stats1.areset_at_mismatch);
            $display("  in: %b (HEX: %h)", stats1.in_at_mismatch, stats1.in_at_mismatch);
            
            // Display Outputs
            $display("Outputs:");
            $display("  Expected (out_ref): %b (HEX: %h)", stats1.out_ref_at_mismatch, stats1.out_ref_at_mismatch);
            $display("  DUT Output (out_dut): %b (HEX: %h)", stats1.out_dut_at_mismatch, stats1.out_dut_at_mismatch);
            
        end else begin
            $display("SIMULATION PASSED");
        end
        
        $display("\n====================================================\n");
        $display("Total mismatched samples (tb_match): %0d out of %0d clocks", stats1.errors, stats1.clocks);
        $display("Total mismatched samples (out_ref check): %0d out of %0d clocks", stats1.errors_out, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("====================================================");
    end
    
    // Verification
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Tracking logic for first mismatch capture and error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Check for any mismatch (tb_match OR internal check)
        if (!tb_match || (out_ref !== ( out_ref ^ out_dut ^ out_ref ))) begin
            // Check if this is the very first mismatch detected for either metric
            if (stats1.errors == 0 && stats1.errors_out == 0) begin
                stats1.errortime = $time;
                stats1.errortime_out = $time;
                
                // Capture signals at the time of the first error
                stats1.in_at_mismatch = in;
                stats1.areset_at_mismatch = areset;
                stats1.out_ref_at_mismatch = out_ref;
                stats1.out_dut_at_mismatch = out_dut;
            end
        end
        
        if (!tb_match) begin
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            stats1.errors_out = stats1.errors_out+1'b1; 
        end
    end
    
    // Output synchronization (Required for accurate snapshot at the transition point)
    always @(posedge clk)
    begin
        capture_in_sig <= in;
        capture_areset_sig <= areset;
        capture_out_ref_sig <= out_ref;
        capture_out_dut_sig <= out_dut;
    end
    
    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule
