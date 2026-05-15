`timescale 1ps/1ps
module stimulus_gen (
    input clk,
    output logic reset,
    output logic w
);

    initial begin
        repeat(200) @(negedge clk) begin
            reset <= ($random & 'h1f) == 0;
            w <= $random;
        end
        #1 $finish;
    end

endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    stats stats1 = '0;
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic w;
    logic z_ref;
    logic z_dut;

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim_gen (
        .clk(clk),
        .reset(reset),
        .w(w)
    );

    RefModule golden (
        .clk(clk),
        .reset(reset),
        .w(w),
        .z(z_ref)
    );

    TopModule dut (
        .clk(clk),
        .reset(reset),
        .w(w),
        .z(z_dut)
    );

    bit strobe = 0;
    task wait_for_end;
        repeat(5) begin
            strobe <= ~strobe;
            @(strobe);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
    end

    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (z_ref !== (z_ref ^ z_dut ^ z_ref)) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z++;
        end
    end

    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end

    final begin
        if (stats1.errors_z) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
            $display("First Mismatch occurred at time %0d: reset=%b, w=%b, z_dut=%b, z_ref=%b", stats1.errortime, reset, w, z_dut, z_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Total mismatched samples: %0d out of %0d", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
endmodule