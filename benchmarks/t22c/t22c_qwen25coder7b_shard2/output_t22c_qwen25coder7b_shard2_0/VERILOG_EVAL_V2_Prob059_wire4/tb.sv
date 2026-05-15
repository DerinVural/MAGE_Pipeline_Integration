`timescale 1ps / 1ps

module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic c
);

    task wavedrom_start(input[511:0] title = "");
        // No action needed for this simulation
    endtask

    task wavedrom_stop;
        #1;
    endtask

    always @(posedge clk, negedge clk)
        {a,b,c} <= $random;

    initial begin
        @(negedge clk) wavedrom_start();
        repeat(8) @(posedge clk);
        @(negedge clk) wavedrom_stop();
        repeat(100) @(negedge clk);
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_w;
        int errortime_w;
        int errors_x;
        int errortime_x;
        int errors_y;
        int errortime_y;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    stats stats1;

    reg clk = 0;
    initial forever
        #5 clk = ~clk;

    logic a;
    logic b;
    logic c;
    logic w_ref;
    logic w_dut;
    logic x_ref;
    logic x_dut;
    logic y_ref;
    logic y_dut;
    logic z_ref;
    logic z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, w_ref, w_dut, x_ref, x_dut, y_ref, y_dut, z_ref, z_dut );
    end

    wire tb_match;       // Verification
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .c(c)
    );

    TopModule top_module1 (
        .a(a),
        .b(b),
        .c(c),
        .w(w_dut),
        .x(x_dut),
        .y(y_dut),
        .z(z_dut)
    );

    initial begin
        w_ref = 0;
        w_dut = 0;
        x_ref = 0;
        x_dut = 0;
        y_ref = 0;
        y_dut = 0;
        z_ref = 0;
        z_dut = 0;
    end

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;  // Try to delay until the very end of the time step.
            @(strobe);
        end
    endtask

    final begin
        if (stats1.errors > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    assign tb_match = ( { w_ref, x_ref, y_ref, z_ref } === ( { w_ref, x_ref, y_ref, z_ref } ^ { w_dut, x_dut, y_dut, z_dut } ^ { w_ref, x_ref, y_ref, z_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            if (w_ref !== ( w_ref ^ w_dut ^ w_ref ))
            begin if (stats1.errors_w == 0) stats1.errortime_w = $time;
                stats1.errors_w = stats1.errors_w + 1'b1; end
            if (x_ref !== ( x_ref ^ x_dut ^ x_ref ))
            begin if (stats1.errors_x == 0) stats1.errortime_x = $time;
                stats1.errors_x = stats1.errors_x + 1'b1; end
            if (y_ref !== ( y_ref ^ y_dut ^ y_ref ))
            begin if (stats1.errors_y == 0) stats1.errortime_y = $time;
                stats1.errors_y = stats1.errors_y + 1'b1; end
            if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
            begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
                stats1.errors_z = stats1.errors_z + 1'b1; end
        end
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule