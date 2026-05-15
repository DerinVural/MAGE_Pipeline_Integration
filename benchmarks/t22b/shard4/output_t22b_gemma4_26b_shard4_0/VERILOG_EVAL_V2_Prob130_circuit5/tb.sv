`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [3:0] a, b, c, d, e,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask

    initial begin
        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) {a, b, c, d, e} <= {20'hab0de};
        repeat(18) @(posedge clk, negedge clk) c <= c + 1;
        wavedrom_stop();

        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) {a, b, c, d, e} <= {20'h12034};
        repeat(8) @(posedge clk, negedge clk) c <= c + 1;
        @(posedge clk) {a, b, c, d, e} <= {20'h56078};
        repeat(8) @(posedge clk, negedge clk) c <= c + 1;
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk)
            {a, b, c, d, e} <= $urandom;
        $finish;
    end
endmodule

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
    initial forever #5 clk = ~clk;

    logic [3:0] a, b, c, d, e;
    logic [3:0] q_ref, q_dut;

    // Dummy RefModule for completeness of the TB structure as per golden TB
    module RefModule (input [3:0] a, b, c, d, e, output [3:0] q);
        assign q = (c == 4'd0) ? b : 
                   (c == 4'd1) ? e : 
                   (c == 4'd2) ? a : 
                   (c == 4'd3) ? d : 4'hf;
    endmodule

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, d, e, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .a,
        .b,
        .c,
        .d,
        .e,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    RefModule good1 (
        .a, .b, .c, .d, .e, .q(q_ref)
    );
        
    TopModule top_module1 (
        .a, .b, .c, .d, .e, .q(q_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    // Track first mismatch details
    logic [3:0] first_a, first_b, first_c, first_d, first_e, first_q_dut, first_q_ref;

    assign tb_match = ( {q_ref} === ( {q_ref} ^ {q_dut} ^ {q_ref} ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end

        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) begin
                stats1.errortime_q = $time;
                first_a = a; first_b = b; first_c = c; first_d = d; first_e = e;
                first_q_dut = q_dut; first_q_ref = q_ref;
            end
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    final begin
        if (stats1.errors_q == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("First Mismatch Details at %0t:", stats1.errortime_q);
            $display("Inputs: a=%h(%b), b=%h(%b), c=%h(%b), d=%h(%b), e=%h(%b)", 
                     first_a, first_a, first_b, first_b, first_c, first_c, first_d, first_d, first_e, first_e);
            $display("Outputs: q_dut=%h(%b), q_ref=%h(%b)", 
                     first_q_dut, first_q_dut, first_q_ref, first_q_ref);
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule