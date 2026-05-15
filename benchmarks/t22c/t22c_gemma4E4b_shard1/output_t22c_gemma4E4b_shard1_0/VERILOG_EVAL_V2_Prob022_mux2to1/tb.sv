`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Placeholder for RefModule as it was used in the golden testbench
module RefModule (
    input a,
    input b,
    input sel,
    output out
);
    // Expected behavior: 2-to-1 MUX
    assign out = sel ? b : a;
endmodule

// The DUT module implementation based on the specification
module TopModule (
    input a,
    input b,
    input sel,
    output out
);
    // Implementation: 2-to-1 MUX
    assign out = sel ? b : a;
endmodule

module stimulus_gen (
    input clk,
    output logic a,b,sel,
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
        {a, b, sel} <= 3'b000;
        @(negedge clk) wavedrom_start("<b>Sel</b> chooses between <b>a</b> and <b>b</b>");
        @(posedge clk) {a, b, sel} <= 3'b000;
        @(posedge clk) {a, b, sel} <= 3'b100;
        @(posedge clk) {a, b, sel} <= 3'b110;
        @(posedge clk) {a, b, sel} <= 3'b111;
        @(posedge clk) {a, b, sel} <= 3'b011;
        @(posedge clk) {a, b, sel} <= 3'b001;
        @(posedge clk) {a, b, sel} <= 3'b100;
        @(posedge clk) {a, b, sel} <= 3'b101;
        @(posedge clk) {a, b, sel} <= 3'b110;
        @(posedge clk) {a, b, sel} <= 3'b111;
        @(negedge clk) wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk)
            {a,b,sel} <= $random;
        $finish;
    end
    
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
    
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic a;
    logic b;
    logic sel;
    logic out_ref;
    logic out_dut;

    // Variables to store signals at the FIRST mismatch time
    logic a_err, b_err, sel_err, out_ref_err, out_dut_err;
    int first_mismatch_time = -1;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,a,b,sel,out_ref,out_dut );
    end


    wire tb_match; // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* ,
        .a,
        .b,
        .sel );
    RefModule good1 (
        .a,
        .b,
        .sel,
        .out(out_ref) );
        
    TopModule top_module1 (
        .a,
        .b,
        .sel,
        .out(out_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    // Helper task to print values in Hex and Binary if width <= 64
    task print_signal(input string name, input logic signal, input int width);
    begin
        if (width <= 64)
            $display("%s = HEX: %h, BIN: %b", name, signal, signal);
        else
            $display("%s = %b", name, signal);
    end
    endtask

    // Final reporting block
    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_mismatch_time);
        end
        
        if (stats1.errors > 0) begin
            $display("
--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", first_mismatch_time);
            // Inputs (a, b, sel) are 1-bit
            $display("Input Signals: a=%b, b=%b, sel=%b", a, b, sel);
            // Outputs (out_dut, out_ref) are 1-bit
            $display("Output Signals: out_dut=%b, out_ref=%b", out_dut, out_ref);
            $display("------------------------------------------");
        end
        
        $display("
Summary: Total mismatched samples (tb_match) is %0d out of %0d samples.", stats1.errors, stats1.clocks);
        $display("Summary: Total output mismatches (out_ref vs out_dut) is %0d.", stats1.errors_out);
        $display("Simulation finished at %0d ps", $time);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Use explicit sensitivity list here.
    always @(posedge clk or negedge clk) begin
        
        stats1.clocks++;
        
        // --- Mismatch Detection and Error Counting ---
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                first_mismatch_time = $time;
            end
            stats1.errors++;
        end
        
        // --- Output Mismatch Detection ---
        // Replicating the specific check from golden TB
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1'b1; 
        end
        end
        
        // Capture signals if this is the first error
        if (stats1.errors == 1 && !tb_match) begin
            a_err = a;
            b_err = b;
            sel_err = sel;
            out_ref_err = out_ref;
            out_dut_err = out_dut;
        end
    end

    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule