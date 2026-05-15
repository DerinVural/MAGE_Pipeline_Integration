module stimulus_gen(clk, a, b, c, d, wavedrom_title, wavedrom_enable, tb_match);
    input clk;
    output logic a, b, c, d;
    output reg [511:0] wavedrom_title;
    output reg wavedrom_enable;
    input tb_match;
    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    bit fail = 0, fail1 = 0;
    always @(posedge clk, negedge clk) if (!tb_match) fail = 1;
    initial begin
        @(posedge clk); {a, b, c, d} <= 0;
        @(posedge clk); {a, b, c, d} <= 1;
        @(posedge clk); {a, b, c, d} <= 2;
        @(posedge clk); {a, b, c, d} <= 4;
        @(posedge clk); {a, b, c, d} <= 5;
        @(posedge clk); {a, b, c, d} <= 6;
        @(posedge clk); {a, b, c, d} <= 7;
        @(posedge clk); {a, b, c, d} <= 9;
        @(posedge clk); {a, b, c, d} <= 10;
        @(posedge clk); {a, b, c, d} <= 13;
        @(posedge clk); {a, b, c, d} <= 14;
        @(posedge clk); {a, b, c, d} <= 15;
        @(posedge clk); fail1 = fail;
        for (int i=0; i<16; i++) @(posedge clk) {a, b, c, d} <= i;
        repeat(50) @(posedge clk) {a, b, c, d} <= $random;
        if (fail && !fail1) $display("Hint: Your circuit passes on the 12 required input combinations, but doesn't match the don't-care cases. Are you using minimal SOP and POS?");
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_sop;
        int errortime_out_sop;
        int errors_out_pos;
        int errortime_out_pos;
        int clocks;
    } stats;
    stats stats1 = '{errors:0, errortime:0, errors_out_sop:0, errortime_out_sop:0, errors_out_pos:0, errortime_out_pos:0, clocks:0};
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a, b, c, d;
    logic out_sop_ref, out_pos_ref;
    logic out_sop_dut, out_pos_dut;
    wire tb_match = ~(({out_sop_ref, out_pos_ref} === ({out_sop_ref, out_pos_ref} ^ {out_sop_dut, out_pos_dut} ^ {out_sop_ref, out_pos_ref} )));
    stimulus_gen stim1(
        .clk(clk),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .wavedrom_title(),
        .wavedrom_enable(),
        .tb_match(tb_match)
    );
    TopModule top_module1(
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out_sop(out_sop_dut),
        .out_pos(out_pos_dut)
    );
    RefModule good1(
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .out_sop(out_sop_ref),
        .out_pos(out_pos_ref)
    );
    initial begin
        #1000000 $display("TIMEOUT");
        $finish();
    end
    task wait_for_end_of_timestep(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    reg strobe = 0;
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            if (out_sop_ref !== (out_sop_ref ^ out_sop_dut ^ out_sop_ref)) begin
                if (stats1.errors_out_sop == 0) stats1.errortime_out_sop = $time;
                stats1.errors_out_sop++;
            end
            if (out_pos_ref !== (out_pos_ref ^ out_pos_dut ^ out_pos_ref)) begin
                if (stats1.errors_out_pos == 0) stats1.errortime_out_pos = $time;
                stats1.errors_out_pos++;
            end
        end
    end
    final begin
        if (stats1.errors_out_sop) $display("Hint: Output 'out_sop' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_out_sop, stats1.errortime_out_sop);
        else $display("Hint: Output 'out_sop' has no mismatches");
        if (stats1.errors_out_pos) $display("Hint: Output 'out_pos' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_out_pos, stats1.errortime_out_pos);
        else $display("Hint: Output 'out_pos' has no mismatches");
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        else $display("SIMULATION PASSED");
        $finish;
    end
endmodule