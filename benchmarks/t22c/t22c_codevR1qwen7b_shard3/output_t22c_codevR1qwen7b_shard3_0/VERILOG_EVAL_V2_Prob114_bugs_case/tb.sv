`timescale 1ps/1ps
module stimulus_gen(input clk, output logic [7:0] code, output reg [511:0] wavedrom_title, output reg wavedrom_enable);
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop(); #1; endtask
    initial begin
        code <= 8'h45;
        @(negedge clk) wavedrom_start("Decode scancodes");
        @(posedge clk) code <= 8'h45;
        code <= 8'h03;
        @(posedge clk);
        code <= 8'h46;
        code <= 8'h16;
        @(posedge clk);
        code <= 8'd26;
        @(posedge clk);
        code <= 8'h1e;
        @(posedge clk);
        code <= 8'h25;
        @(posedge clk);
        code <= 8'h26;
        @(posedge clk);
        code <= $random;
        @(posedge clk);
        code <= 8'h36;
        @(posedge clk);
        code <= $random;
        @(posedge clk);
        code <= 8'h3d;
        @(posedge clk);
        code <= 8'h3e;
        @(posedge clk);
        code <= 8'h45;
        @(posedge clk);
        code <= 8'h46;
        @(posedge clk);
        code <= $random;
        @(posedge clk);
        code <= $random;
        @(posedge clk);
        code <= $random;
        @(posedge clk);
        wavedrom_stop();
        repeat(1000) @(posedge clk, negedge clk) code <= $urandom;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int errors_valid;
        int errortime_valid;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [7:0] code;
    logic [3:0] out_ref;
    logic [3:0] out_dut;
    logic valid_ref;
    logic valid_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1(.clk(clk), .code(code), .wavedrom_title(wavedrom_title), .wavedrom_enable(wavedrom_enable));
    RefModule good1(.code(code), .out(out_ref), .valid(valid_ref));
    TopModule top_module1(.code(code), .out(out_dut), .valid(valid_dut));
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    final begin
        if (stats1.errors_out) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else $display("SIMULATION PASSED");
        $display("First mismatch: code=%h (%b), out_ref=%h (%b), out_dut=%h (%b), valid_ref=%b, valid_dut=%b", code, code, out_ref, out_ref, out_dut, out_dut, valid_ref, valid_dut);
    end
    // ... (rest of the original testbench code, including error counting and timeout)
endmodule
