`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input logic clk,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
        wavedrom_enable <= 1;
        wavedrom_title <= title;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable <= 0;
    endtask    

    initial begin
        wavedrom_enable = 0;
        wavedrom_title = 0;
        wavedrom_start("Output should 0");
        repeat(20) @(posedge clk, negedge clk);
        wavedrom_stop();
        
        #1 $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_zero;
        int errortime_zero;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic zero_ref;
    logic zero_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, zero_ref, zero_dut);
    end

    wire tb_match;        // Verification
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*  );

    // RefModule is assumed to be provided by the environment
    RefModule good1 (
        .zero(zero_ref) );
        
    TopModule top_module1 (
        .zero(zero_dut) );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask    

    final begin
        if (stats1.errors_zero) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "zero", stats1.errors_zero, stats1.errortime_zero);
        else 
            $display("Hint: Output '%s' has no mismatches.", "zero");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);

        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
    end
    
    // Verification
    assign tb_match = ( { zero_ref } === ( { zero_ref } ^ { zero_dut } ^ { zero_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("FIRST MISMATCH DETECTED at time %0t ps", $time);
                $display("  Inputs: None");
                $display("  Output: zero = %b (HEX: %h, BIN: %b)", zero_dut, zero_dut, zero_dut);
                $display("  Expected: zero = %b", zero_ref);
            end
            stats1.errors++;
        end

        if (zero_ref !== ( zero_ref ^ zero_dut ^ zero_ref )) begin 
            if (stats1.errors_zero == 0) stats1.errortime_zero = $time;
            stats1.errors_zero = stats1.errors_zero + 1'b1; 
        end
    end

    initial begin
        stats1.errors = 0;
        stats1.errortime = 0;
        stats1.errors_zero = 0;
        stats1.errortime_zero = 0;
        stats1.clocks = 0;

        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule