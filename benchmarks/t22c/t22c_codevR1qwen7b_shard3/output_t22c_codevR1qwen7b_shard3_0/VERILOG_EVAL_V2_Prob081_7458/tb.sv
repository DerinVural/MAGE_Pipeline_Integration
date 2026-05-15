module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_p1y;
        int errortime_p1y;
        int errors_p2y;
        int errortime_p2y;
        int clocks;
    } stats;
    stats stats1 = '0;

    logic clk = 0;
    initial forever #5 clk = ~clk;

    logic p1a, p1b, p1c, p1d, p1e, p1f;
    logic p2a, p2b, p2c, p2d;
    logic p1y_ref, p2y_ref;
    logic p1y_dut, p2y_dut;

    stimulus_gen stim1 (.clk(clk),
        .p1a(p1a), .p1b(p1b), .p1c(p1c), .p1d(p1d), .p1e(p1e), .p1f(p1f),
        .p2a(p2a), .p2b(p2b), .p2c(p2c), .p2d(p2d));

    TopModule top_module1 (
        .p1a(p1a), .p1b(p1b), .p1c(p1c), .p1d(p1d), .p1e(p1e), .p1f(p1f),
        .p2a(p2a), .p2b(p2b), .p2c(p2c), .p2d(p2d),
        .p1y(p1y_dut), .p2y(p2y_dut));

    RefModule ref_mod (
        .p1a(p1a), .p1b(p1b), .p1c(p1c), .p1d(p1d), .p1e(p1e), .p1f(p1f),
        .p2a(p2a), .p2b(p2b), .p2c(p2c), .p2d(p2d),
        .p1y(p1y_ref), .p2y(p2y_ref));

    wire tb_match = ({p1y_ref, p2y_ref} === ({p1y_ref, p2y_ref} ^ {p1y_dut, p2y_dut} ^ {p1y_ref, p2y_ref}));

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (p1y_ref !== (p1y_ref ^ p1y_dut ^ p1y_ref)) begin
            if (stats1.errors_p1y == 0) stats1.errortime_p1y = $time;
            stats1.errors_p1y++;
        end
        if (p2y_ref !== (p2y_ref ^ p2y_dut ^ p2y_ref)) begin
            if (stats1.errors_p2y == 0) stats1.errortime_p2y = $time;
            stats1.errors_p2y++;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb, clk, p1a, p1b, p1c, p1d, p1e, p1f, p2a, p2b, p2c, p2d, p1y_ref, p1y_dut, p2y_ref, p2y_dut);
    end

    final begin
        if (stats1.errors_p1y) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_p1y, stats1.errortime_p1y);
        else if (stats1.errors_p2y) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_p2y, stats1.errortime_p2y);
        else if (stats1.errors) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        else $display("SIMULATION PASSED");
        $finish;
    end

    initial #1000000 $finish;
endmodule

module stimulus_gen (input clk, output logic p1a, p1b, p1c, p1d, p1e, p1f, p2a, p2b, p2c, p2d);
    task wavedrom_start; input [511:0] title; endtask
    task wavedrom_stop; #1; endtask

    int count;
    initial begin
        count = 0;
        {p1a,p1b,p1c,p1d,p1e,p1f} = 0;
        {p2a,p2b,p2c,p2d} = 0;
        wavedrom_start();
        repeat(20) @(posedge clk) begin
            {p1a,p1b,p1c,p1d,p1e,p1f} <= {count[2:0], count[3:1], 3'b0};
            {p2a,p2b,p2c,p2d} <= count;
            count++;
        end
        wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk) begin
            {p1a,p1b,p1c,p2a,p2b,p2c,p2d} <= $random;
        end
        #1 $finish;
    end
endmodule

module TopModule (p1a, p1b, p1c, p1d, p1e, p1f, p2a, p2b, p2c, p2d, p1y, p2y);
    input p1a, p1b, p1c, p1d, p1e, p1f;
    input p2a, p2b, p2c, p2d;
    output logic p1y, p2y;
    wire and1_out = p1a & p1b & p1c;
    wire and2_out = p1d & p1e & p1f;
    assign p1y = and1_out | and2_out;
    wire and3_out = p2a & p2b;
    wire and4_out = p2c & p2d;
    assign p2y = and3_out | and4_out;
endmodule

module RefModule (
    input p1a, p1b, p1c, p1d, p1e, p1f,
    input p2a, p2b, p2c, p2d,
    output logic p1y, p2y
);
    // Reference implementation here (if needed)
endmodule