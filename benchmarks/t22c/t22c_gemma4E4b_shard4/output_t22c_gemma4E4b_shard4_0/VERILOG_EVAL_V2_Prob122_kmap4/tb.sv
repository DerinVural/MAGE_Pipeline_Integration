
`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Assume RefModule exists and functions as expected in the original setup
module RefModule (
    input logic a, b, c, d,
    output logic out
);
    // Placeholder implementation for compilation, actual logic depends on system context
    assign out = a & b | c ^ d;
endmodule

// Stimulus Generator (Copied exactly from golden testbench)
module stimulus_gen (
	input clk,
	output reg a, b, c, d,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		int count; count = 0;
		{a,b,c,d} <= 4'b0;
		wavedrom_start();
		repeat(16) @(posedge clk)
			{a,b,c,d} <= count++;	
		@(negedge clk) wavedrom_stop();
		
		repeat(200) @(posedge clk, negedge clk)
			{d,c,b,a} <= $urandom;
		
		#1 $finish;
	end
	endmodule

// The DUT Module implementing the K-Map logic
module TopModule (
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic out
);

    // K-map logic implementation
    //             ab
    //  cd   00  01  11  10
    //  00 | 0 | 1 | 0 | 1 |
    //  01 | 1 | 0 | 1 | 0 |
    //  11 | 0 | 1 | 0 | 1 |
    //  10 | 1 | 0 | 1 | 0 |
    always_comb begin
        case ({a, b, c, d}) 
            4'b0000: out = 1'b0; // 00/00
            4'b0001: out = 1'b1; // 00/01
            4'b0011: out = 1'b0; // 00/11
            4'b0010: out = 1'b1; // 00/10
            4'b0100: out = 1'b1; // 01/00
            4'b0101: out = 1'b0; // 01/01
            4'b0111: out = 1'b1; // 01/11
            4'b0110: out = 1'b0; // 01/10
            4'b1100: out = 1'b0; // 11/00
            4'b1101: out = 1'b1; // 11/01
            4'b1111: out = 1'b0; // 11/11
            4'b1110: out = 1'b1; // 11/10
            4'b1000: out = 1'b1; // 10/00
            4'b1001: out = 1'b0; // 10/01
            4'b1011: out = 1'b1; // 10/11
            4'b1010: out = 1'b0; // 10/10
            default: out = 1'bx;
        endcase
    end
endmodule

// Testbench
module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;

        int clocks;
    } stats;
    
    stats stats1;
    
    // Variables to store the first mismatch details
    logic [3:0] first_mismatch_inputs = 4'bxxxx;
    logic first_mismatch_output_ref = 1'bx;
    logic first_mismatch_output_dut = 1'bx;
    int first_mismatch_time = 0;

    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic a;
    logic b;
    logic c;
    logic d;
    logic out_ref;
    logic out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        // Updated dumpvars to include new state capture variables
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, d, out_ref, out_dut, first_mismatch_inputs, first_mismatch_output_ref, first_mismatch_output_dut, first_mismatch_time);
        
        stats1.errors = 0;
        stats1.clocks = 0;
        stats1.errors_out = 0;
        stats1.errortime_out = 0;
        first_mismatch_time = 0;
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate Stimulus Generator
    stimulus_gen stim1 (
        .clk, 
        .* , // Catch-all for wavedrom_title and wavedrom_enable
        .a, 
        .b, 
        .c, 
        .d 
    );
    
    // Instantiate Reference Module
    RefModule good1 (
        .a, 
        .b, 
        .c, 
        .d,
        .out(out_ref) 
    );
        
    // Instantiate DUT
    TopModule top_module1 (
        .a, 
        .b, 
        .c, 
        .d,
        .out(out_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask	

    // Helper task for formatted display
    task display_signal(input string name, input logic value, input string type_hint = "BIT");
        $write("%-25s: ", name);
        if (type_hint == "BIT") begin
            $write("$b%b");
        end else begin
            // Assuming multi-bit signals would be handled here, using $h for hex if necessary
            $write("$h);
        end
        $display(" ");
    endtask

    // Task to display detailed state at the first mismatch
    task display_first_mismatch;
        $display("====================================================");
        $display("*** FIRST MISMATCH DETECTED AT TIME %0d ps ***", first_mismatch_time);
        $display("----------------------------------------------------");
        $display("Inputs:");
        display_signal("a", a);
        display_signal("b", b);
        display_signal("c", c);
        display_signal("d", d);
        $display("Output Signals:");
        display_signal("Reference Output (Expected)", out_ref);
        display_signal("DUT Output (Actual)", out_dut);
        $display("====================================================");
    endtask


    final begin
        // 1. Check for mismatches
        if (stats1.errors == 0) begin
            $display("\n=========================================");
            $display("SIMULATION PASSED");
            $display("=========================================");
        end else begin
            // 2. Display failure message
            $display("\n=========================================");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, first_mismatch_time);
            
            // 3. Display detailed state at the first mismatch
            display_first_mismatch();
            $display("=========================================");
        end

        $display("\nTotal mismatched samples is %1d out of %1d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Clocked verification and error counting
    always @(posedge clk, negedge clk) begin

        // Update clock count
        stats1.clocks++;

        if (!tb_match) begin
            // --- Mismatch Detected ---
            if (stats1.errors == 0) begin
                // Capture state ONLY on the very first mismatch
                first_mismatch_time = $time;
                first_mismatch_inputs = {a, b, c, d};
                first_mismatch_output_ref = out_ref;
                first_mismatch_output_dut = out_dut;
            end
            
            stats1.errors++;

            // Original logic for output specific error tracking (kept for compliance)
            if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
            begin 
                if (stats1.errors_out == 0) stats1.errortime_out = $time;
                stats1.errors_out = stats1.errors_out+1'b1; 
            end
        end
    end

   // Add timeout after 100K cycles
   initial begin
     #1000000
     $display("\nTIMEOUT REACHED");
     $finish();
   end

endmodule
