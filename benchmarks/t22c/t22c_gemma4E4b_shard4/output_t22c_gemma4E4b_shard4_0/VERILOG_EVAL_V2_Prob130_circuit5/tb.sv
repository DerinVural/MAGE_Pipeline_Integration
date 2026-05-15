`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Placeholder for RefModule as it's used in the original testbench structure
module RefModule (
    input [3:0] a,
    input [3:0] b,
    input [3:0] c,
    input [3:0] d,
    input [3:0] e,
    output logic [3:0] q
);
    // Placeholder logic: To allow simulation to run, we assign a placeholder.
    assign q = 4'hAAAA; 
endmodule

// stimulus_gen module structure preserved from golden testbench
module stimulus_gen (
    input clk,
    output logic [3:0] a,b,c,d,e,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
        
    initial begin
        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) {a,b,c,d,e} <= {20'hab0de};
        repeat(18) @(posedge clk, negedge clk) c <= c + 1;
        wavedrom_stop();

        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) {a,b,c,d,e} <= {20'h12034};
        repeat(8) @(posedge clk, negedge clk) c <= c + 1;
        @(posedge clk) {a,b,c,d,e} <= {20'h56078};
        repeat(8) @(posedge clk, negedge clk) c <= c + 1;
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk)
        {a,b,c,d,e} <= $urandom;
        $finish;
    end
    	endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;

        int clocks;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [3:0] a;
    logic [3:0] b;
    logic [3:0] c;
    logic [3:0] d;
    logic [3:0] e;
    logic [3:0] q_ref;
    logic [3:0] q_dut;

    // Variables to store the state at the first mismatch
    integer first_mismatch_time = -1;
    logic [3:0] first_mismatch_a, first_mismatch_b, first_mismatch_c, first_mismatch_d, first_mismatch_e;
    logic [3:0] first_mismatch_q_ref, first_mismatch_q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,a,b,c,d,e,q_ref,q_dut );
    end

    
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .a, 
        .b,
        .c,
        .d,
        .e );
    RefModule good1 (
        .a,
        .b,
        .c,
        .d,
        .e,
        .q(q_ref) );
        
    TopModule top_module1 (
        .a,
        .b,
        .c,
        .d,
        .e,
        .q(q_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    final begin
        if (stats1.errors > 0) begin
            $display("
=======================================================================================");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", stats1.errortime);
            
            // Display Inputs
            $display("Inputs: A=%h (%b), B=%h (%b), C=%h (%b), D=%h (%b), E=%h (%b)", 
                first_mismatch_a, first_mismatch_b, first_mismatch_c, first_mismatch_d, first_mismatch_e);
            // Display Outputs
            $display("Outputs: Q_REF=%h (%b), Q_DUT=%h (%b)", 
                first_mismatch_q_ref, first_mismatch_q_dut);
            
            $display("=======================================================================================");
        end
        
        if (stats1.errors == 0) begin
            $display("
=======================================================================================");
            $display("SIMULATION PASSED");
            $display("=======================================================================================");
        end
        
        $display("
Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
    
    // Use explicit sensitivity list here.
    always @(posedge clk, negedge clk) begin
        
        stats1.clocks++;
        
        // Check for DUT mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                // Capture inputs/outputs at the very first error time
                first_mismatch_time = $time;
                first_mismatch_a = a; first_mismatch_b = b; first_mismatch_c = c; first_mismatch_d = d; first_mismatch_e = e;
                first_mismatch_q_ref = q_ref; first_mismatch_q_dut = q_dut;
            end
            stats1.errors++;
        end
        
        // Check for Q reference mismatch (original logic)
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
        begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q+1'b1; // Fixed typo
        end
    end

    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("
TIMEOUT REACHED");
        $finish();
    end

    // Monitor signals for debugging (Optional, but good practice)
    initial begin
        $monitor("Time=%0t | A=%h B=%h C=%h D=%h E=%h | Q_REF=%h | Q_DUT=%h | Match=%b", 
            $time, a, b, c, d, e, q_ref, q_dut, tb_match);
    end

endmodule