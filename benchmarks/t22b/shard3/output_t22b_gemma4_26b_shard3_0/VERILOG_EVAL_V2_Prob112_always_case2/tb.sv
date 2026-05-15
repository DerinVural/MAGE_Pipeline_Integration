`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [3:0] in, 
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable    
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        in <= 4'b0;
        wavedrom_enable <= 0;
        wavedrom_title <= 512'b0;
        @(negedge clk) wavedrom_start("Priority encoder");
            @(posedge clk) in <= 4'h1;
            repeat(4) @(posedge clk) in <= in << 1;
            in <= 0;
            repeat(16) @(posedge clk) in <= in + 1;
        @(negedge clk) wavedrom_stop();

        repeat(50) @(posedge clk, negedge clk) begin
            in <= $urandom;
        end
        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_pos;
        int errortime_pos;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever
        #5 clk = ~clk;

    logic [3:0] in;
    logic [1:0] pos_ref;
    logic [1:0] pos_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, in, pos_ref, pos_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .in 
    );

    RefModule good1 (
        .in,
        .pos(pos_ref) 
    );
        
    TopModule top_module1 (
        .in,
        .pos(pos_dut) 
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { pos_ref } === ( { pos_ref } ^ { pos_dut } ^ { pos_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            if (stats1.errors == 1) begin
                $display("FIRST MISMATCH DETECTED at time %0t:", $time);
                $display("  in      = %h (%b)", in, in);
                $display("  pos_ref = %h (%b)", pos_ref, pos_ref);
                $display("  pos_dut = %h (%b)", pos_dut, pos_dut);
            end
        end

        if (pos_ref !== ( pos_ref ^ pos_dut ^ pos_ref )) begin 
            if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
            stats1.errors_pos = stats1.errors_pos + 1'b1; 
        end
    end

    initial begin
        stats1 = '{0, 0, 0, 0, 0};
        #1000000
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_pos) 
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "pos", stats1.errors_pos, stats1.errortime_pos);
        else 
            $display("Hint: Output '%s' has no mismatches.", "pos");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule