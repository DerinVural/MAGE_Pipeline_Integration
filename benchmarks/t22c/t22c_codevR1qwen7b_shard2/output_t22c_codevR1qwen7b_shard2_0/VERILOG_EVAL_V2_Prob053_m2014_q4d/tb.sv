`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic in
);
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            in <= $random;
        end
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
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic in;
    logic out_ref;
    logic out_dut;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, in, out_ref, out_dut);
    end
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (.clk(clk), .in(in));
    TopModule top_module1 (.clk(clk), .in(in), .out(out_dut));
    RefModule good1 (.clk(clk), .in(in), .out(out_ref));
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    final begin
        if (stats1.errors_out) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
            $display("First Mismatch: in=%b, out_ref=%b, out_dut=%b", in, out_ref, out_dut);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Total mismatched samples: %0d out of %0d", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    assign tb_match = ( {out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== ({out_ref} ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    // Timeout after 1e6 cycles
    initial begin
        #1000000 $display("TIMEOUT");
        $finish();
    end
endmodule