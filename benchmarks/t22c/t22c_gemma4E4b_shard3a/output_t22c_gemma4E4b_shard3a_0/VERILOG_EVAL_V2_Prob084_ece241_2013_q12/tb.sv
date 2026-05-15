`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assuming RefModule is defined elsewhere or we provide a placeholder for compilation
module RefModule(
    input clk,
    input enable,
    input S,
    input A,
    input B,
    input C,
    output Z
);
    // Placeholder implementation for reference checking based on the required function.
    // Following the original golden TB's placeholder logic.
    assign Z = A & B & C; 
endmodule

module stimulus_gen (
    input clk,
    output logic S, enable,
    output logic A, B, C,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);


// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask 


    initial begin
        enable <= 0;
        {A,B,C} <= 0;
        S <= 1'bx;
        @(negedge clk) wavedrom_start("A 3-input AND gate");
            @(posedge clk);
            @(posedge clk) enable <= 1; S <= 1;
            @(posedge clk) S <= 0;
            @(posedge clk) S <= 0;
            @(posedge clk) S <= 0;
            @(posedge clk) S <= 0;
            @(posedge clk) S <= 0;
            @(posedge clk) S <= 0;
            @(posedge clk) enable <= 0; S <= 1'bx;
            {A,B,C} <= 5;
            @(posedge clk) {A,B,C} <= 6;
            @(posedge clk) {A,B,C} <= 7;
            @(posedge clk) {A,B,C} <= 0;
            @(posedge clk) {A,B,C} <= 1;
        @(negedge clk) wavedrom_stop();

        repeat(500) @(posedge clk, negedge clk) begin
            {A,B,C,S} <= $random;
            enable <= ($random&3) == 0;
        end
        
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_Z;
        int errortime_Z;
        int clocks;
    } stats;
    
    stats stats1;
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic enable;
    logic S;
    logic A;
    logic B;
    logic C;
    logic Z_ref;
    logic Z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stimulus_gen.clk, tb_mismatch ,clk,enable,S,A,B,C,Z_ref,Z_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk, 
        .enable, 
        .S, 
        .A, 
        .B, 
        .C);
        
    RefModule good1 (
        .clk, 
        .enable, 
        .S, 
        .A, 
        .B, 
        .C,
        .Z(Z_ref) );
        
    TopModule top_module1 (
        .clk, 
        .enable, 
        .S, 
        .A, 
        .B, 
        .C,
        .Z(Z_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask 

    
    initial begin
        stats1.errors = 0;
        stats1.errors_Z = 0;
        stats1.clocks = 0;
        
        $display("Starting simulation...");
        
        @(posedge clk);
    end

    // Monitoring logic
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        // Check for general mismatch
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // Check for Z mismatch
        if (Z_ref !== Z_dut) 
        begin 
            if (stats1.errors_Z == 0) stats1.errortime_Z = $time;
            stats1.errors_Z = stats1.errors_Z + 1'b1;
        end
        end
        
        // Display inputs/outputs on FIRST mismatch (where stats1.errors == 1)
        if (stats1.errors == 1) begin
            if (!tb_match || (Z_ref !== Z_dut)) begin
                $display("
========================================================");
                $display("!!! FIRST MISMATCH DETECTED AT TIME %0d ps !!!", $time);
                $display("--- Inputs ---");
                $display("clk: %b", clk);
                $display("enable: %b (Hex: %h)", enable, enable);
                $display("S: %b (Hex: %h)", S, S);
                $display("A: %b (Hex: %h), B: %b (Hex: %h), C: %b (Hex: %h)", A, A, B, B, C, C);
                $display("--- Outputs ---");
                $display("Z_dut: %b (Hex: %h)", Z_dut, Z_dut);
                $display("Z_ref (Expected): %b (Hex: %h)", Z_ref, Z_ref);
                $display("========================================================
");
            end
        end
    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0 && stats1.errors_Z == 0) begin
            $display("SIMULATION PASSED");
            $display("Simulation finished at %0d ps", $time);
            $display("Mismatches: 0 in %0d samples", stats1.clocks);
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("Simulation finished at %0d ps", $time);
            $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        end
    end

endmodule