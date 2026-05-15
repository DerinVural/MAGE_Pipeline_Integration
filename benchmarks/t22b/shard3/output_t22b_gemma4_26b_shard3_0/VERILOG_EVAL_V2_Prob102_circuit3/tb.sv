module RefModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);
    always_comb begin
        case ({a, b, c, d})
            4'b0101: q = 1'b1;
            4'b0110: q = 1'b1;
            4'b0111: q = 1'b1;
            4'b1001: q = 1'b1;
            4'b1010: q = 1'b1;
            4'b1011: q = 1'b1;
            4'b1101: q = 1'b1;
            4'b1110: q = 1'b1;
            4'b1111: q = 1'b1;
            default: q = 1'b0;
        endcase
    end
endmodule

`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input  logic clk,
    output logic a, b, c, d,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask
    
    task wavedrom_stop;
        #1;
        wavedrom_enable = 0;
    endtask

    initial begin
        {a,b,c,d} <= 0;
        @(negedge clk) wavedrom_start("Unknown circuit");
        @(posedge clk) {a,b,c,d} <= 0;
        repeat(18) @(posedge clk, negedge clk) {a,b,c,d} <= {a,b,c,d} + 1;
        wavedrom_stop();
        
        repeat(100) @(posedge clk, negedge clk)
            {a,b,c,d} <= $urandom;
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
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic a;
    logic b;
    logic c;
    logic d;
    logic q_ref;
    logic q_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, d, q_ref, q_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .a,
        .b,
        .c,
        .d,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    RefModule good1 (
        .a,
        .b,
        .c,
        .d,
        .q(q_ref) 
    );
        
    TopModule top_module1 (
        .a,
        .b,
        .c,
        .d,
        .q(q_dut) 
    );

    task wait_for_end_of_timestep;
        bit strobe = 0;
        repeat(5) begin
            strobe = !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("Mismatch detected at time %0t: inputs(a=%b, b=%b, c=%b, d=%b), expected q=%b, got q=%b", 
                         $time, a, b, c, d, q_ref, q_dut);
            end
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin 
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q = stats1.errors_q + 1'b1;
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors_q == 0 && stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
        end

        if (stats1.errors_q) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "q", stats1.errors_q, stats1.errortime_q);
        else $display("Hint: Output '%s' has no mismatches.", "q");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule