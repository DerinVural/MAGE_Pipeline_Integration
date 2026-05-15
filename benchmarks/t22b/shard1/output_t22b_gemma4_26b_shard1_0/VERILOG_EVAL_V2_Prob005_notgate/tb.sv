`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output reg in,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
        wavedrom_enable <= 1'b1;
        wavedrom_title <= title;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable <= 1'b0;
    endtask    

    initial begin
        in <= 1'b0;
        wavedrom_enable <= 1'b0;
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
        $dumpvars(1, stim1.clk, tb_mismatch, in, out_ref, out_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .in
    );

    // Note: RefModule is assumed to be provided by the environment to avoid re-declaration errors.
    RefModule good1 (
        .in,
        .out(out_ref)
    );
        
    TopModule top_module1 (
        .in,
        .out(out_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin 
            if (stats1.errors_out == 0) begin 
                stats1.errortime_out = $time;
                $display("FIRST MISMATCH DETECTED at time %0d: in=%b, out_dut=%b, out_ref=%b (expected=%b)", $time, in, out_dut, out_ref, out_ref);
            end
            stats1.errors_out = stats1.errors_out + 1'b1;
        end
    end

    final begin
        if (stats1.errors_out == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end

        if (stats1.errors_out) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out", stats1.errors_out, stats1.errortime_out);
        else 
            $display("Hint: Output '%s' has no mismatches.", "out");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule