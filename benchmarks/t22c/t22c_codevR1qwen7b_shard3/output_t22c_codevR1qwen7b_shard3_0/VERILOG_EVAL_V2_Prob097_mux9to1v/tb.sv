`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic [15:0] a,
    output logic [15:0] b,
    output logic [15:0] c,
    output logic [15:0] d,
    output logic [15:0] e,
    output logic [15:0] f,
    output logic [15:0] g,
    output logic [15:0] h,
    output logic [15:0] i,
    output logic [3:0] sel,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop(); #1; endtask
    initial begin
        {a,b,c,d,e,f,g,h,i,sel} <= {
            16'ha, 16'hb, 16'hc, 16'hd, 16'he, 16'hf, 16'h11, 16'h12, 16'h13, 4'h0
        };
        @(negedge clk);
        wavedrom_start();
        @(posedge clk) sel <= 4'h1;
        @(posedge clk) sel <= 4'h2;
        @(posedge clk) sel <= 4'h3;
        @(posedge clk) sel <= 4'h4;
        @(posedge clk) sel <= 4'h7;
        @(posedge clk) sel <= 4'h8;
        @(posedge clk) sel <= 4'h9;
        @(posedge clk) sel <= 4'ha;
        @(posedge clk) sel <= 4'hb;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(negedge clk, posedge clk) begin
            {a,b,c,d,e,f,g,h,i,sel} <= {
                $random, $random, $random, $random, $random
            };
        end
        $finish;
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
    stats stats1 = '{errors:0, errortime:0, errors_out:0, errortime_out:0, clocks:0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [15:0] a;
    logic [15:0] b;
    logic [15:0] c;
    logic [15:0] d;
    logic [15:0] e;
    logic [15:0] f;
    logic [15:0] g;
    logic [15:0] h;
    logic [15:0] i;
    logic [3:0] sel;
    logic [15:0] out_ref;
    logic [15:0] out_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h), .i(i), .sel(sel),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h), .i(i), .sel(sel),
        .out(out_ref)
    );
    TopModule top_module1 (
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .h(h), .i(i), .sel(sel),
        .out(out_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep();
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    assign tb_match = ({out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            $display("ERROR AT TIME %0d: out_ref=%h out_dut=%h Expected %h", $time, out_ref, out_dut, {out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}) ? out_ref : out_dut);
        end
        if (out_ref !== ({out_ref} ^ {out_dut} ^ {out_ref})) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish;
    end
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Total errors: %0d", stats1.errors);
    end
endmodule
