`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Helper module for reference (Must match interface of TopModule)
module RefModule (
    input clk,
    input a,
    input b,
    output logic q,
    output logic state
);
    // Placeholder implementation to allow simulation to run.
    // In a real scenario, this would contain the golden reference logic.
    assign q = 1'b0; 
    assign state = 1'b0;
endmodule

module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
        
    initial begin
        a <= 1;
        @(negedge clk) {a,b} <= 0;
        @(negedge clk) wavedrom_start("Unknown circuit");
            repeat(3) @(posedge clk);
            {a,b} <= 1;
            @(posedge clk) {a,b} <= 2;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 3;
            @(posedge clk) {a,b} <= 2;
            @(posedge clk) {a,b} <= 1;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 0;
            @(posedge clk) {a,b} <= 0;
            @(negedge clk);
            wavedrom_stop();

            repeat(200) @(posedge clk, negedge clk)
                a <= &((5)'($urandom));
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int errors_state;
        int errortime_state;

        int clocks;
    } stats;
    
    stats stats1;
    
    // Snapshot storage for first error details
    logic snap_clk, snap_a, snap_b, snap_q_ref, snap_q_dut, snap_state_ref, snap_state_dut;
    int snap_errortime = 0;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic a;
    logic b;
    logic q_ref;
    logic q_dut;
    logic state_ref;
    logic state_dut;

    initial begin 
        $dumpfile("wave.vcd");
        dumpvars(1, stim1.clk, tb_mismatch ,clk,a,b,q_ref,q_dut,state_ref,state_dut );
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator
    stimulus_gen stim1 (
        .clk,
        .a,
        .b,
        .wavedrom_title,
        .wavedrom_enable
    );
    
    // Reference Model
    RefModule good1 (
        .clk,
        .a,
        .b,
        .q(q_ref),
        .state(state_ref) );
        
    // DUT Instance (Must match TopModule interface exactly)
    TopModule top_module1 (
        .clk,
        .a,
        .b,
        .q(q_dut),
        .state(state_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Verification Match Logic
    // Match only if both outputs match
    assign tb_match = (q_ref === q_dut) && (state_ref === state_dut);

    // Clocked Logic for Counting and Error Tracking
    always @(posedge clk, negedge clk) begin

        stats1.clocks++;
        
        // 1. Total Mismatch Tracking
        if (!tb_match) begin
            if (stats1.errors == 0) { stats1.errortime = $time; snap_errortime = $time; }
            stats1.errors++;
        end
        
        // 2. Q Mismatch Tracking
        if (q_ref !== q_dut) begin
            if (stats1.errors_q == 0) { stats1.errortime_q = $time; }
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
        
        // 3. State Mismatch Tracking
        if (state_ref !== state_dut) begin
            if (stats1.errors_state == 0) { stats1.errortime_state = $time; }
            stats1.errors_state = stats1.errors_state + 1'b1;
        end

    end

    // Snapshotting values at the time of first error
    always @(*) begin
        if (stats1.errors == 1) begin
            snap_clk = clk;
            snap_a = a;
            snap_b = b;
            snap_q_ref = q_ref;
            snap_q_dut = q_dut;
            snap_state_ref = state_ref;
            snap_state_dut = state_dut;
        end
    end

    final begin
        $display("===================================================");
        $display("SIMULATION SUMMARY");
        $display("===================================================");
        
        if (stats1.errors > 0) begin
            // Required Failure Display Format
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("-----------------------------------------------------");
            $display("--- Signals Snapshot at Time %0d ps (First Mismatch) ---", snap_errortime);
            
            // Required Input Display (Single bit, binary format) 
            $display("Inputs: A=%b, B=%b", snap_a, snap_b);
            
            // Required Reference Output Display (Single bit, binary format) 
            $display("Reference Outputs: Q_ref=%b, State_ref=%b", snap_q_ref, snap_state_ref);
            
            // Required DUT Output Display (Single bit, binary format) 
            $display("DUT Outputs: Q_dut=%b, State_dut=%b", snap_q_dut, snap_state_dut);
            $display("-----------------------------------------------------");
            
            // Detailed per-output failure reporting (Maintaining original logic)
            if (stats1.errors_q > 0) begin
                $display("Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
                $display("  Snapshot at q failure: Q_ref=%b, Q_dut=%b", snap_q_ref, snap_q_dut);
            end
            if (stats1.errors_state > 0) begin
                $display("Output 'state' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_state, stats1.errortime_state);
                $display("  Snapshot at state failure: State_ref=%b, State_dut=%b", snap_state_ref, snap_state_dut);
            end
        end
        
        if (stats1.errors == 0) begin
            // Required Success Display Format
            $display("SIMULATION PASSED");
        end
        
        $display("===================================================");
        $display("Simulation finished at %0d ps", $time);
        $display("Total Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule