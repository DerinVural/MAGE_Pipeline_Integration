`timescale 1ps/1ps

module stimulus_gen(input clk, output [511:0] wavedrom_title, output wavedrom_enable);
    task wavedrom_start(input [511:0] title = 
    endtask
    task wavedrom_stop; #1; endtask
    initial begin
        wavedrom_start("Output should 0");
        repeat(20) @(posedge clk, negedge clk);
        wavedrom_stop();
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_zero;
        int errortime_zero;
        int clocks;
    } stats;
    stats stats1 = '{errors:0, errortime:0, errors_zero:0, errortime_zero:0, clocks:0};
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic zero_ref;
    logic zero_dut;
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1(.clk(clk), .wavedrom_title(wavedrom_title), .wavedrom_enable(wavedrom_enable));
    RefModule good1(.zero(zero_ref));
    TopModule top_module1(.zero(zero_dut));
    bit strobe = 0;
    task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    final begin
        if (stats1.errors_zero)
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_zero, stats1.errortime_zero);
        else
            $display("SIMULATION PASSED");
        $display("Simulation finished at %0d ps", $time);
    end
    assign tb_match = ({zero_ref} === ({zero_ref} ^ {zero_dut} ^ {zero_ref}));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (zero_ref !== (zero_ref ^ zero_dut ^ zero_ref)) begin
            if (stats1.errors_zero == 0) stats1.errortime_zero = $time;
            stats1.errors_zero++;
        end
    end
    initial #1000000 $display("TIMEOUT") && $finish();
endmodule