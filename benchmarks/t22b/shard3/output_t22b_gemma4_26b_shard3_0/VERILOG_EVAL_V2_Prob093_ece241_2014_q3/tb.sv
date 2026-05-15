`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic c, d,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        {c, d} <= 0;
        @(negedge clk) wavedrom_start();
            @(posedge clk) {c, d} <= 2'h0;
            @(posedge clk) {c, d} <= 2'h1;
            @(posedge clk) {c, d} <= 2'h2;
            @(posedge clk) {c, d} <= 2'h3;
        @(negedge clk) wavedrom_stop();
        repeat(50) @(posedge clk, negedge clk)
            {c,d} <= $random;

        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_mux_in;
        int errortime_mux_in;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic c;
    logic d;
    logic [3:0] mux_in_ref;
    logic [3:0] mux_in_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, c, d, mux_in_ref, mux_in_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .c,
        .d
    );

    // RefModule is assumed to be provided by the environment per the error log.
    // If not, it would be declared here.
    RefModule good1 (
        .c,
        .d,
        .mux_in(mux_in_ref)
    );
        
    TopModule top_module1 (
        .c,
        .d,
        .mux_in(mux_in_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { mux_in_ref } === ( { mux_in_ref } ^ { mux_in_dut } ^ { mux_in_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            if (stats1.errors == 1) begin
                $display("FIRST MISMATCH AT TIME %0t:", $time);
                $display("Inputs: c=%b, d=%b", c, d);
                $display("Expected mux_in: %h (%b)", mux_in_ref, mux_in_ref);
                $display("Actual mux_in:   %h (%b)", mux_in_dut, mux_in_dut);
            end
        end

        if (mux_in_ref !== ( mux_in_ref ^ mux_in_dut ^ mux_in_ref )) begin
            if (stats1.errors_mux_in == 0) stats1.errortime_mux_in = $time;
            stats1.errors_mux_in = stats1.errors_mux_in + 1'b1;
        end
    end

    initial begin
      #1000000;
      $display("TIMEOUT");
      $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_mux_in) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "mux_in", stats1.errors_mux_in, stats1.errortime_mux_in);
        else 
            $display("Hint: Output '%s' has no mismatches.", "mux_in");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule