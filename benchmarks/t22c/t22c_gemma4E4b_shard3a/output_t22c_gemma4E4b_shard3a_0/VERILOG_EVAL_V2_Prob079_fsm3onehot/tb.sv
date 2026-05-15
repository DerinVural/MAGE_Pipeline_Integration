`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// --- Mocked RefModule based on Specification ---
module RefModule (
    input in,
    input state [3:0],
    output next_state [3:0],
    output out
);
    // One-hot encoding: A=4'b0001, B=4'b0010, C=4'b0100, D=4'b1000
    parameter STATE_A = 4'b0001;
    parameter STATE_B = 4'b0010;
    parameter STATE_C = 4'b0100;
    parameter STATE_D = 4'b1000;

    // State transition and output logic derived from the table
    // State | Next state in=0, Next state in=1 | Output
    // A     | A, B                             | 0
    // B     | C, B                             | 0
    // C     | A, D                             | 0
    // D     | C, B                             | 1

    // Combinational logic implementation
    always @* begin
        // Default assignments
        next_state = 4'b0000;
        out = 1'b0;

        case (state) 
            STATE_A:
                if (in == 0) next_state = STATE_A; else next_state = STATE_B;
                out = 1'b0;
            STATE_B:
                if (in == 0) next_state = STATE_C; else next_state = STATE_B;
                out = 1'b0;
            STATE_C:
                if (in == 0) next_state = STATE_A; else next_state = STATE_D;
                out = 1'b0;
            STATE_D:
                if (in == 0) next_state = STATE_C; else next_state = STATE_B;
                out = 1'b1;
            default:
                next_state = 4'b0000;
                out = 1'b0;
        endcase
    end
endmodule
// -------------------------------------------------

module stimulus_gen (
    input clk,
    output logic in,
    output logic [3:0] state,
    input tb_match
);

    initial begin
        // Test the one-hot cases first.
        repeat(200) @(posedge clk, negedge clk) begin
            state <= 1<< ($unsigned($random) % 4);
            in <= $random;
        end
            
        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_next_state;
        int errortime_next_state;
        int errors_out;
        int errortime_out;

        int clocks;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic in;
    logic [3:0] state;
    logic [3:0] next_state_ref;
    logic [3:0] next_state_dut;
    logic out_ref;
    logic out_dut;

    // Queueing definitions for sequential checking
    // State width = 4 bits. Max Queue Size limited to 10.
    localparam MAX_QUEUE_SIZE = 10;

    // Inputs to check
    reg [3:0] input_state_queue [$];
    reg input_in_queue [$];
    
    // Outputs to check
    reg [3:0] got_next_state_queue [$];
    reg [1:0] got_out_queue [$]; // Concatenating next_state_dut and out_dut for easier comparison if needed, but we check separately
    reg [3:0] golden_next_state_queue [$];
    reg [1:0] golden_out_queue [$];
    
    // Reset queue (not used explicitly in original logic, but required by prompt structure)
    reg reset_queue [$]; 

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,in,state,next_state_ref,next_state_dut,out_ref,out_dut );
    end


    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .in,
        .state,
        .tb_match 
    );
    RefModule good1 (
        .in,
        .state,
        .next_state(next_state_ref),
        .out(out_ref) 
    );
        
    TopModule top_module1 (
        .in,
        .state,
        .next_state(next_state_dut),
        .out(out_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask 

    // --- Queue Management and Mismatch Logging ---
    always @(posedge clk, negedge clk) begin
        // 1. Maintain Queue Size
        if (input_state_queue.size() >= MAX_QUEUE_SIZE - 1) begin
            input_state_queue.delete(0);
            input_in_queue.delete(0);
            golden_next_state_queue.delete(0);
            golden_out_queue.delete(0);
            got_next_state_queue.delete(0);
            got_out_queue.delete(0);
            reset_queue.delete(0);
        end

        // 2. Push current cycle data (State transition logic is sequential, so we check on posedge clk)
        input_state_queue.push_back(state);
        input_in_queue.push_back(in);
        
        golden_next_state_queue.push_back(next_state_ref);
        golden_out_queue.push_back({out_ref, 1'b0}); // Store {out_ref, 0} to maintain 2-bit structure for easier display

        got_next_state_queue.push_back(next_state_dut);
        got_out_queue.push_back({out_dut, 1'b0}); // Store {out_dut, 0} for consistency
        
        reset_queue.push_back(1'b0); // Assuming no explicit reset is used in the original logic

        // 3. Check for first mismatch (using simplified comparison: {NSR, OR} == {NDS, OUD})
        if (next_state_ref !== next_state_dut || out_ref !== out_dut) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            $display("
======================================================");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", stats1.errors, stats1.errortime);
            $display("Displaying last %0d cycles leading up to and including the first error.", input_state_queue.size());
            $display("======================================================");

            // Display Queue Content
            for (int i = 0; i < input_state_queue.size(); i++) begin
                $display("Cycle %0d (Time %0d): ", i, $time - (input_state_queue.size() - 1 - i) * 10);
                
                // Inputs
                $display("  Inputs: State = %b (%h), In = %b", input_state_queue[i], input_state_queue[i], input_in_queue[i]);
                
                // Outputs
                $display("  Expected Outputs: Next_State = %b (%h), Out = %b", golden_next_state_queue[i], golden_next_state_queue[i], golden_out_queue[i][0]);
                $display("  Got Outputs: Next_State = %b (%h), Out = %b", got_next_state_queue[i], got_next_state_queue[i], got_out_queue[i][0]);
                
                // Mismatch indication
                if (golden_next_state_queue[i] !== got_next_state_queue[i] || golden_out_queue[i][0] !== got_out_queue[i][0]) begin
                    $display("  *** MISMATCH DETECTED AT THIS CYCLE ***");
                end
            end
        end
    end
    // --- End of Queue Management ---

    // Original Verification Logic (Preserved functionality, though queue handles logging)
    assign tb_match = ( { next_state_ref, out_ref } === { next_state_dut, out_dut } );

    // Original Error Counting Logic (Must be preserved)
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        // Original, redundant check: if (next_state_ref !== ( next_state_ref ^ next_state_dut ^ next_state_ref ))
        // This simplifies to if (next_state_ref !== next_state_dut)
        if (next_state_ref !== next_state_dut)
        begin if (stats1.errors_next_state == 0) stats1.errortime_next_state = $time;
            stats1.errors_next_state = stats1.errors_next_state+1'b1; end
        end
        // Original, redundant check: if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        // This simplifies to if (out_ref !== out_dut)
        if (out_ref !== out_dut)
        begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out+1'b1; end
        end
    end

   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("\n--- TIMEOUT REACHED ---\n");
     $finish();
   end

   // Finalization Block (Updated based on new requirement)
   final begin
       if (stats1.errors == 0)
           $display("\n========================================");
           $display("SIMULATION PASSED");
           $display("========================================");
       else begin
           $display("\n========================================");
           $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
           $display("========================================");
       end
       $display("Simulation finished at %0d ps", $time);
       $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
   end

endmodule
