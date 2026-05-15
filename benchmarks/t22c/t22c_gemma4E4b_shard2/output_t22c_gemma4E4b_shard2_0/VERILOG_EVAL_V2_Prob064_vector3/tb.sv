/* Testbench improved to meet display requirements. */

`timescale 1 ps/1 ps

// Redefining constants from the golden testbench
`define OK 12
`define INCORRECT 13

// Forward declarations/stubs for modules used in the golden testbench
module stimulus_gen (
	input clk,
	output logic [4:0] a,b,c,d,e,f,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable
);

	task wavedrom_start(input[511:0] title = "");
	endtask
	
task wavedrom_stop;
		#1;
	endtask

	initial begin
		wavedrom_start("");
		@(posedge clk) {a,b,c,d,e,f} <= '0;
		@(posedge clk) {a,b,c,d,e,f} <= 1;
		@(posedge clk) {a,b,c,d,e,f} <= 2;
		@(posedge clk) {a,b,c,d,e,f} <= 4;
		@(posedge clk) {a,b,c,d,e,f} <= 8;
		@(posedge clk) {a,b,c,d,e,f} <= 'h10;
		@(posedge clk) {a,b,c,d,e,f} <= 'h20;
		@(posedge clk) {a,b,c,d,e,f} <= 'h40;
		@(posedge clk) {a,b,c,d,e,f} <= 'h80;
		@(posedge clk) {a,b,c,d,e,f} <= 'h100;
		@(posedge clk) {a,b,c,d,e,f} <= 'h200;
		@(posedge clk) {a,b,c,d,e,f} <= 'h400;
		@(posedge clk) {a,b,c,d,e,f} <= {5'h1f, 5'h0, 5'h1f, 5'h0, 5'h1f, 5'h0};
		@(negedge clk);
		wavedrom_stop();
		repeat(100) @(posedge clk, negedge clk)
		{a,b,c,d,e,f} <= $random;
		$finish;
	end
endmodule

// Stub for RefModule since its implementation is not provided but its interface is used
module RefModule (
    input [4:0] a, b, c, d, e, f,
    output logic [7:0] w, x, y, z
);
    // Dummy implementation for compilation
    assign w = 8'h00;
    assign x = 8'h00;
    assign y = 8'h00;
    assign z = 8'h00;
endmodule

// DUT Module (Placeholder - uses the interface defined in the golden testbench)
module TopModule (
    input  [4:0] a,
    input  [4:0] b,
    input  [4:0] c,
    input  [4:0] d,
    input  [4:0] e,
    input  [4:0] f,
    output [7:0] w,
    output [7:0] x,
    output [7:0] y,
    output [7:0] z
);
    // Dummy implementation for compilation
    assign w = 8'h00;
    assign x = 8'h00;
    assign y = 8'h00;
    assign z = 8'h00;
endmodule

module tb();

    // Helper task to display signals in required format
    task display_signals(input time,
                        input logic [4:0] in_a, in_b, in_c, in_d, in_e, in_f,
                        input logic [7:0] ref_w, ref_x, ref_y, ref_z,
                        input logic [7:0] dut_w, dut_x, dut_y, dut_z);
        $display(
            "============================================================")
        ;
        $display("--- MISMATCH DETECTED AT TIME %0t ps ---", time);
        
        // Display Inputs (5 bits)
        $display("
--- INPUT SIGNALS (Time: %0t ps) ---", time);
        $display("a: HEX=%h, BIN=%b", in_a, in_a);
        $display("b: HEX=%h, BIN=%b", in_b, in_b);
        $display("c: HEX=%h, BIN=%b", in_c, in_c);
        $display("d: HEX=%h, BIN=%b", in_d, in_d);
        $display("e: HEX=%h, BIN=%b", in_e, in_e);
        $display("f: HEX=%h, BIN=%b", in_f, in_f);
        
        // Display Expected Outputs (8 bits)
        $display("
--- EXPECTED OUTPUTS (Reference) ---");
        $display("w_ref: HEX=%h, BIN=%b", ref_w, ref_w);
        $display("x_ref: HEX=%h, BIN=%b", ref_x, ref_x);
        $display("y_ref: HEX=%h, BIN=%b", ref_y, ref_y);
        $display("z_ref: HEX=%h, BIN=%b", ref_z, ref_z);
        
        // Display Actual Outputs (DUT)
        $display("
--- ACTUAL OUTPUTS (DUT) ---");
        $display("w_dut: HEX=%h, BIN=%b", dut_w, dut_w);
        $display("x_dut: HEX=%h, BIN=%b", dut_x, dut_x);
        $display("y_dut: HEX=%h, BIN=%b", dut_y, dut_y);
        $display("z_dut: HEX=%h, BIN=%b", dut_z, dut_z);
        $display("============================================================");
    endtask


    typedef struct packed {
        int errors;
        int errortime;
        int errors_w;
        int errortime_w;
        int errors_x;
        int errortime_x;
        int errors_y;
        int errortime_y;
        int errors_z;
        int errortime_z;

        int clocks;
    } stats;
    
    stats stats1;
    
    // Variables to store data at the FIRST mismatch
    logic [4:0] first_err_a, first_err_b, first_err_c, first_err_d, first_err_e, first_err_f;
    logic [7:0] first_err_w_ref, first_err_x_ref, first_err_y_ref, first_err_z_ref;
    logic [7:0] first_err_w_dut, first_err_x_dut, first_err_y_dut, first_err_z_dut;

    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [4:0] a;
    logic [4:0] b;
    logic [4:0] c;
    logic [4:0] d;
    logic [4:0] e;
    logic [4:0] f;
    logic [7:0] w_ref;
    logic [7:0] w_dut;
    logic [7:0] x_ref;
    logic [7:0] x_dut;
    logic [7:0] y_ref;
    logic [7:0] y_dut;
    logic [7:0] z_ref;
    logic [7:0] z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, tb);
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    // Instantiate stimulus generator (as per golden testbench)
    stimulus_gen stim1 (
        .clk,
        .a, .b, .c, .d, .e, .f, 
        .wavedrom_title, 
        .wavedrom_enable 
    );
    
    // Instantiate Reference Module
    RefModule good1 (
        .a, .b, .c, .d, .e, .f,
        .w(w_ref),
        .x(x_ref),
        .y(y_ref),
        .z(z_ref) 
    );
        
    // Instantiate DUT
    TopModule top_module1 (
        .a, .b, .c, .d, .e, .f,
        .w(w_dut),
        .x(x_dut),
        .y(y_dut),
        .z(z_dut) 
    );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Capture data on the first mismatch
    always @(posedge clk, negedge clk)
    begin
        if (!tb_match && stats1.errors == 0) begin
            // This is the first mismatch
            stats1.errortime = $time;
            // Capture inputs
            first_err_a <= a;
            first_err_b <= b;
            first_err_c <= c;
            first_err_d <= d;
            first_err_e <= e;
            first_err_f <= f;
            // Capture expected outputs
            first_err_w_ref <= w_ref;
            first_err_x_ref <= x_ref;
            first_err_y_ref <= y_ref;
            first_err_z_ref <= z_ref;
            // Capture actual outputs
            first_err_w_dut <= w_dut;
            first_err_x_dut <= x_dut;
            first_err_y_dut <= y_dut;
            first_err_z_dut <= z_dut;
        end
        
        stats1.clocks++;
        if (!tb_match) begin
            stats1.errors++;
        end
        
        // Original error counting logic
        if (w_ref !== w_dut)
        begin if (stats1.errors_w == 0) stats1.errortime_w = $time;
            stats1.errors_w = stats1.errors_w + 1'b1; end
        end
        if (x_ref !== x_dut)
        begin if (stats1.errors_x == 0) stats1.errortime_x = $time;
            stats1.errors_x = stats1.errors_x + 1'b1; end
        end
        if (y_ref !== y_dut)
        begin if (stats1.errors_y == 0) stats1.errortime_y = $time;
            stats1.errors_y = stats1.errors_y + 1'b1; end
        end
        if (z_ref !== z_dut)
        begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1'b1; end
        end

    end

    // Verification assignment (Using XOR technique from golden testbench)
    assign tb_match = ( { w_ref, x_ref, y_ref, z_ref } === ( { w_ref, x_ref, y_ref, z_ref } ^ { w_dut, x_dut, y_dut, z_dut } ^ { w_ref, x_ref, y_ref, z_ref } ) );
    
    // add timeout after 100K cycles
    initial begin
        #1000000
        $display("TIMEOUT REACHED.");
        $finish();
    end

    // Finalization block (Updated to meet new reporting requirements)
    final begin
        if (stats1.errors == 0) begin
            $display("\n************************************************************");
            $display("SIMULATION PASSED");
            $display("************************************************************");
        end else begin
            $display("\n************************************************************");
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", 
                    stats1.errors, stats1.errortime);
            
            // Display detailed information for the first mismatch
            display_signals(
                stats1.errortime, 
                first_err_a, first_err_b, first_err_c, first_err_d, first_err_e, first_err_f,
                first_err_w_ref, first_err_x_ref, first_err_y_ref, first_err_z_ref,
                first_err_w_dut, first_err_x_dut, first_err_y_dut, first_err_z_dut
            );
            
            // Original detailed error reports (kept for completeness)
            if (stats1.errors_w) $display("Hint: Output 'w' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_w, stats1.errortime_w);
            if (stats1.errors_x) $display("Hint: Output 'x' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_x, stats1.errortime_x);
            if (stats1.errors_y) $display("Hint: Output 'y' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_y, stats1.errortime_y);
            if (stats1.errors_z) $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);

            $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
            $display("Simulation finished at %0d ps", $time);
        end
    
    end

endmodule