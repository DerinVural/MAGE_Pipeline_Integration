`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic        clk,
    output logic [7:0]  d,
    output logic [511:0] wavedrom_title,
    output logic        wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    always @(posedge clk, negedge clk)
        d <= $random % 256;
    
    initial begin
        @(posedge clk);
        wavedrom_start("Positive-edge triggered DFF");
        repeat(10) @(posedge clk);
        wavedrom_stop();
        #100;
        $finish;
    end
endmodule

// Only define RefModule if it hasn't been defined by the environment to avoid redefinition errors
`ifndef REF_MODULE_DEFINED
module RefModule (
    input  logic        clk,
    input  logic [7:0]  d,
    output logic [7:0]  q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule
`define REF_MODULE_DEFINED
`endif

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk = 0;
    initial forever
        #5 clk = ~clk;

    logic [7:0] d;
    logic [7:0] q_ref;
    logic [7:0] q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, d, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .d
    );

    RefModule good1 (
        .clk,
        .d,
        .q(q_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .d,
        .q(q_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    // Display for the first mismatch
    bit first_mismatch_logged = 0;
    always @(posedge clk) begin
        if (!tb_match && !first_mismatch_logged && stats1.errors_q > 0) begin
            $display("First mismatch detected at time %0t:", $time);
            $display("d: %h (%b)", d, d);
            $display("q_dut: %h (%b)", q_dut, q_dut);
            $display("q_ref: %h (%b)", q_ref, q_ref);
            first_mismatch_logged = 1;
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors_q > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
            $display("Hint: Output '%s' has no mismatches.", "q");
        end

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule