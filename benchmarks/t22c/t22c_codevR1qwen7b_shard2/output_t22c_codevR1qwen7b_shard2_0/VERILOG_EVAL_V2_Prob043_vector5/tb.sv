`timescale 1ps/1ps
module tb();
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic a, b, c, d, e;
    logic [24:0] out_ref, out_dut;
    int errors = 0, errortime = 0, errors_out = 0;

    // Stimulus generation
    stimulus_gen stim(.clk(clk), .a(a), .b(b), .c(c), .d(d), .e(e));

    // Reference module
    RefModule ref_mod(.a(a), .b(b), .c(c), .d(d), .e(e), .out(out_ref));
    // DUT
    TopModule dut(.a(a), .b(b), .c(c), .d(d), .e(e), .out(out_dut));

    // Check mismatch
    always @(negedge clk) begin
        if (out_ref !== out_dut) begin
            if (errors == 0) errortime = $time;
            errors++;
        end
        errors_out++;
    end

    // Simulation end and display
    final begin
        if (errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
            $display("First Mismatch at time %0d: a=%b, b=%b, c=%b, d=%b, e=%b\nout_dut=%b (expected %b)", errortime, a, b, c, d, e, out_dut, out_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
    end

    // Timeout after 100K cycles
    initial begin
        #100_000 $display("TIMEOUT");
        $finish;
    end
endmodule

module stimulus_gen(input clk, output logic a, b, c, d, e);
    initial begin
        repeat(100) @(posedge clk, negedge clk) {a,b,c,d,e} = $random;
        $finish;
    end
endmodule

module RefModule(input a, b, c, d, e, output [24:0] out);
    assign out[24] = ~(a == a);
    assign out[23] = ~(a == b);
    assign out[22] = ~(a == c);
    assign out[21] = ~(a == d);
    assign out[20] = ~(a == e);
    assign out[19] = ~(b == a);
    assign out[18] = ~(b == b);
    assign out[17] = ~(b == c);
    assign out[16] = ~(b == d);
    assign out[15] = ~(b == e);
    assign out[14] = ~(c == a);
    assign out[13] = ~(c == b);
    assign out[12] = ~(c == c);
    assign out[11] = ~(c == d);
    assign out[10] = ~(c == e);
    assign out[9] = ~(d == a);
    assign out[8] = ~(d == b);
    assign out[7] = ~(d == c);
    assign out[6] = ~(d == d);
    assign out[5] = ~(d == e);
    assign out[4] = ~(e == a);
    assign out[3] = ~(e == b);
    assign out[2] = ~(e == c);
    assign out[1] = ~(e == d);
    assign out[0] = ~(e == e);
endmodule