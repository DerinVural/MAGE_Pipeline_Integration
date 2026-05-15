`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [255:0] in,
    output logic [7:0] sel
);

    always @(posedge clk, negedge clk) begin
        for (int i=0; i<8; i++)
            in[i*32 +: 32] <= $random;
        sel <= $random;
    end

    initial begin
        repeat(1000) @(negedge clk);
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

    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [255:0] in;
    logic [7:0] sel;
    logic out_ref;
    logic out_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, in, sel, out_ref, out_dut);
    end

    wire tb_match, tb_mismatch;
    assign tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .sel(sel)
    );

    RefModule good1 (
        .in(in),
        .sel(sel),
        .out(out_ref)
    );

    TopModule top_module1 (
        .in(in),
        .sel(sel),
        .out(out_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    // Error checking
    assign tb_match = ( { out_ref } === ( { out_ref } ^ { out_dut } ^ { out_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        // Check output error
        if (out_ref !== ( out_ref ^ out_dut ^ out_ref )) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1;
        end
    end

    // Timeout after 100K cycles
    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("Input signals: in = %h%h, sel = %h", in[255:192], in[191:0], sel);
            $display("Output signals: out = %b, Expected = %b", out_dut, out_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Total errors: %0d/%0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end
endmodule