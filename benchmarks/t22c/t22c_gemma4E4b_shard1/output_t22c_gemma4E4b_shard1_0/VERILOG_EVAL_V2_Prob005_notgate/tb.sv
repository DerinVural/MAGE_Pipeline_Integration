`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

// Reusing stimulus_gen from golden testbench as it drives the inputs
module stimulus_gen (
    input clk,
    output reg in,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask
    
    initial begin
        in <= 1'b0;
        wavedrom_start("Inversion");
        repeat(20) @(posedge clk)
            in <= $random;	
        wavedrom_stop();
        
        repeat(200) @(posedge clk, negedge clk)
            in <= $random;
            	
        #1 $finish;
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

    logic in;
    logic out_ref;
    logic out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        // Using stimulus_gen::stim1 as per the previous structure
        $dumpvars(1, stimulus_gen::stim1, tb_mismatch ,in,out_ref,out_dut );
    end


    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .* , 
        .in );
    RefModule good1 (
        .in,
        .out(out_ref) );
        
    TopModule top_module1 (
        .in,
        .out(out_dut) );

    
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    
    // Variables to track first mismatch timing and data
    integer first_mismatch_time = 0;
    logic first_mismatch_occurred = 0;

    final begin
        // Determine the earliest failure time
        int earliest_time = 1000000000; // A large number
        
        if (stats1.errors > 0 && stats1.errortime < earliest_time) begin
            earliest_time = stats1.errortime;
        end
        if (stats1.errors_out > 0 && stats1.errortime_out < earliest_time) begin
            earliest_time = stats1.errortime_out;
        end

        if (stats1.errors == 0 && stats1.errors_out == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            // SIMULATION FAILED reporting: Use the earliest time found
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d.", (stats1.errors > 0 ? stats1.errors : stats1.errors_out), earliest_time);
        
            $display("
--- FIRST MISMATCH DETAILS (Time: %0d ps) ---", earliest_time);
            
            // Display required signals at the earliest mismatch time
            // Since inputs/outputs are single bit logic, we display as binary.
            $display("Input Signal (in): %b", in);
            $display("Output DUT Signal (out_dut): %b", out_dut);
            $display("Expected Output Signal (out_ref): %b", out_ref);
            $display("-----------------------------------");
            
            // Retain original summary statistics
            $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
            $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        end
    
    end
    
    // Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );
    
    // Use explicit sensitivity list here.
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        
        // Logic for errors_out (based on original check)
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref ))
        begin 
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out+1'b1; 
        end
    end

    // add timeout after 100K cycles
    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule