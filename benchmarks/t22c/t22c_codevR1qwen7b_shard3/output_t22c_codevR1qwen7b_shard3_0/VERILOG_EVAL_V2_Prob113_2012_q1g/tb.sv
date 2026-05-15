`timescale 1ps/1ps
module tb();
    typedef struct packed { int errors; int errortime; int errors_f; int errortime_f; int clocks; } stats;
    stats stats1 = '{0,0,0,0,0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [3:0] x;
    logic f_ref;
    logic f_dut;
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1( .clk(clk), .x(x) );
    RefModule good1( .x(x), .f(f_ref) );
    TopModule top_module1( .x(x), .f(f_dut) );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (f_ref !== (f_ref ^ f_dut ^ f_ref)) begin
            if (stats1.errors_f == 0) stats1.errortime_f = $time;
            stats1.errors_f++;
        end
    end
    initial begin #1000000; $display("TIMEOUT"); $finish(); end
    final begin
        if (stats1.errors_f) begin
            $display("Hint: Output f has %0d mismatches. First at %0d", stats1.errors_f, stats1.errortime_f);
        end else {
            $display("No mismatches in f");
        }
        if (stats1.errors) begin
            $display("%0d errors out of %0d", stats1.errors, stats1.clocks);
        end else {
            $display("Simulation PASSED");
        }
        $finish;
    end
endmodule