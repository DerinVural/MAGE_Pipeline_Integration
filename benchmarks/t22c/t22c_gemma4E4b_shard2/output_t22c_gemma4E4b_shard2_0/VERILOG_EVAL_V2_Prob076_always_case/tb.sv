`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Implementation of the DUT based on the specification (6-to-1 Mux)
module TopModule (input logic [2:0] sel, input logic [3:0] data0, input logic [3:0] data1, input logic [3:0] data2, input logic [3:0] data3, input logic [3:0] data4, input logic [3:0] data5, output logic [3:0] out);
    assign out = case (sel) 
        3'b000: data0 
        3'b001: data1 
        3'b010: data2 
        3'b011: data3 
        3'b100: data4 
        3'b101: data5 
        default: 4'b0000 
    endcase;
endmodule

// Stimulus Generator (Copied from Golden Testbench)
module stimulus_gen (
    input clk,
    output logic [2:0] sel, 
    output logic [3:0] data0,
    output logic [3:0] data1,
    output logic [3:0] data2,
    output logic [3:0] data3,
    output logic [3:0] data4,
    output logic [3:0] data5,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask


    initial begin
        data0 <= 4'ha;
        data1 <= 4'hb;
        data2 <= 4'hc;
        data3 <= 4'hd;
        data4 <= 4'he;
        data5 <= 4'hf;
        {sel} <= 3'b111;
        @(negedge clk) wavedrom_start("<b>Sel</b> chooses one of the data inputs");
            repeat(8) @(posedge clk) sel <= sel + 1;
        @(negedge clk) wavedrom_stop();

        repeat(100) @(posedge clk, negedge clk) begin
            {data0, data1, data2, data3} <= $urandom;
            {data4, data5, sel} <= $urandom;
        end
        $finish;
    end
    
endmodule

// Dummy RefModule to satisfy testbench instantiation (assuming it mirrors TopModule)
module RefModule (input logic [2:0] sel, input logic [3:0] data0, input logic [3:0] data1, input logic [3:0] data2, input logic [3:0] data3, input logic [3:0] data4, input logic [3:0] data5, output logic [3:0] out);
    assign out = case (sel) 
        3'b000: data0 
        3'b001: data1 
        3'b010: data2 
        3'b011: data3 
        3'b100: data4 
        3'b101: data5 
        default: 4'b0000 
    endcase;
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

    logic [2:0] sel;
    logic [3:0] data0;
    logic [3:0] data1;
    logic [3:0] data2;
    logic [3:0] data3;
    logic [3:0] data4;
    logic [3:0] data5;
    logic [3:0] out_ref;
    logic [3:0] out_dut;

    // Variables to capture first mismatch details
    logic [3:0] first_mismatch_data0;
    logic [3:0] first_mismatch_data1;
    logic [3:0] first_mismatch_data2;
    logic [3:0] first_mismatch_data3;
    logic [3:0] first_mismatch_data4;
    logic [3:0] first_mismatch_data5;
    logic [2:0] first_mismatch_sel;
    logic [3:0] first_mismatch_out_ref;
    logic [3:0] first_mismatch_out_dut;
    int first_mismatch_time = 0;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,sel,data0,data1,data2,data3,data4,data5,out_ref,out_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* , 
        .sel,
        .data0,
        .data1,
        .data2,
        .data3,
        .data4,
        .data5 );
    RefModule good1 (
        .sel,
        .data0,
        .data1,
        .data2,
        .data3,
        .data4,
        .data5,
        .out(out_ref) );
        
    TopModule top_module1 (
        .sel,
        .data0,
        .data1,
        .data2,
        .data3,
        .data4,
        .data5,
        .out(out_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask


    // Verification assignment
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

    // Clocked comparison and error counting
always @(posedge clk, negedge clk) begin

        stats1.clocks++;

        // Check for DUT mismatch (Primary Error Count)
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            // Capture first mismatch details
            if (first_mismatch_time == 0) begin
                first_mismatch_time = $time;
                first_mismatch_sel = sel;
                first_mismatch_data0 = data0;
                first_mismatch_data1 = data1;
                first_mismatch_data2 = data2;
                first_mismatch_data3 = data3;
                first_mismatch_data4 = data4;
                first_mismatch_data5 = data5;
                first_mismatch_out_ref = out_ref;
                first_mismatch_out_dut = out_dut;
            end
        end
        
        // Original logic for stats1.errors_out (kept for compliance)
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin if (stats1.errors_out == 0) stats1.errortime_out = $time;
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


    // Final Reporting Block
    final begin
        if (stats1.errors_out > 0) begin
            $display("\n========================================================\n");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
            $display("--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", first_mismatch_time);
            
            // Display Inputs and Outputs (All signals <= 4 bits, so HEX and BIN are displayed)
            $display("Inputs: sel=%h (%b), data0=%h (%b), data1=%h (%b), data2=%h (%b), data3=%h (%b), data4=%h (%b), data5=%h (%b)", 
                first_mismatch_sel, first_mismatch_sel, 
                first_mismatch_data0, first_mismatch_data0, 
                first_mismatch_data1, first_mismatch_data1, 
                first_mismatch_data2, first_mismatch_data2, 
                first_mismatch_data3, first_mismatch_data3, 
                first_mismatch_data4, first_mismatch_data4, 
                first_mismatch_data5, first_mismatch_data5);
            $display("Expected Output (out_ref): %h (%b)", first_mismatch_out_ref, first_mismatch_out_ref);
            $display("Actual Output (out_dut): %h (%b)", first_mismatch_out_dut, first_mismatch_out_dut);
            $display("========================================================\n");
        end else begin
            $display("\n========================================================\n");
            $display("SIMULATION PASSED");
            $display("========================================================\n");
        end

        $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule