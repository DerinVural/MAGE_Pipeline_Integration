`timescale 1ps/1ps
module stimulus_gen (input clk, output logic in, output logic [511:0] wavedrom_title, output logic wavedrom_enable );
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        wavedrom_start("Output should follow input");
        repeat(20) @(posedge clk, negedge clk) in <= $random;
        wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) in <= $random;
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed { int errors; int errortime; int errors_out; int errortime_out; int clocks; } stats;
    stats stats1 = 0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic in;
    logic out_ref, out_dut;
    logic [63:0] in_display, out_ref_display, out_dut_display;
    logic [63:0] in_binary, out_ref_binary, out_dut_binary;
    wire tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) );
    stimulus_gen stim1 ( .clk(clk), .in(in), .wavedrom_title(wavedrom_title), .wavedrom_enable(wavedrom_enable) );
    RefModule good1 ( .in(in), .out(out_ref) );
    TopModule top_module1 ( .in(in), .out(out_dut) );
    initial begin
        stats1.errors = 0;
        stats1.errortime = 0;
        stats1.errors_out = 0;
        stats1.errortime_out = 0;
        stats1.clocks = 0;
    end
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            in_display = in;
            out_ref_display = out_ref;
            out_dut_display = out_dut;
            in_binary = in;
            out_ref_binary = out_ref;
            out_dut_binary = out_dut;
            $display("First mismatch at time %0d: in=%h, out_ref=%h, out_dut=%h", $time, in_display, out_ref_display, out_dut_display);
            if (64 >= 64) begin
                $display("Binary: in=%b, out_ref=%b, out_dut=%b", in_binary, out_ref_binary, out_dut_binary);
            end
        end
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out += 1;
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule