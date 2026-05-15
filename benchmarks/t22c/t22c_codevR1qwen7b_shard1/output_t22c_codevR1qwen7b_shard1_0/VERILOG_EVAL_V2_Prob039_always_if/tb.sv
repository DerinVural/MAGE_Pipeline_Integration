`timescale 1ps/1ps

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_assign;
        int errortime_out_assign;
        int errors_out_always;
        int errortime_out_always;
        int clocks;
    } stats;

    stats stats1 = '{errors:0, errortime:0, errors_out_assign:0, errortime_out_assign:0, errors_out_always:0, errortime_out_always:0, clocks:0};
    wire clk;
    logic a, b, sel_b1, sel_b2;
    logic out_assign_ref, out_assign_dut;
    logic out_always_ref, out_always_dut;
    logic tb_match, tb_mismatch;

    // Clock generation
    reg clk_reg = 0;
    always #5 clk_reg = ~clk_reg;
    assign clk = clk_reg;

    // Instantiate modules
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .wavedrom_title(), // Not used in testbench, tied off
        .wavedrom_enable()
    );

    RefModule ref_mod (
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .out_assign(out_assign_ref),
        .out_always(out_always_ref)
    );

    TopModule top_mod (
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .out_assign(out_assign_dut),
        .out_always(out_always_dut)
    );

    // Test stimulus
    initial begin
        a = 0;
        b = 0;
        sel_b1 = 0;
        sel_b2 = 0;
        // Additional test vectors...
        repeat(100) @(posedge clk); // Adjust as needed
        $finish;
    end

    // Monitoring and error checking
    always @(posedge clk) begin
        stats1.clocks++;
        if (({out_assign_ref, out_always_ref} === ({out_assign_ref, out_always_ref} ^ {out_assign_dut, out_always_dut} ^ {out_assign_ref, out_always_ref}))) !== tb_match) begin
            $display("First mismatch at time %0d", $time);
            $display("Input a: %b, b: %b, sel_b1: %b, sel_b2: %b", a, b, sel_b1, sel_b2);
            $display("Outputs (Ref, DUT): assign=%b %b, always=%b %b", out_assign_ref, out_assign_dut, out_always_ref, out_always_dut);
        end
        // Update error counts
        if (out_assign_ref !== out_assign_dut) begin
            if (stats1.errors_out_assign == 0) stats1.errortime_out_assign = $time;
            stats1.errors_out_assign++;
        end
        if (out_always_ref !== out_always_dut) begin
            if (stats1.errors_out_always == 0) stats1.errortime_out_always = $time;
            stats1.errors_out_always++;
        end
        if (stats1.errors == 0 && (out_assign_ref !== out_assign_dut || out_always_ref !== out_always_dut)) begin
            stats1.errortime = $time;
        end
        stats1.errors += (out_assign_ref !== out_assign_dut) + (out_always_ref !== out_always_dut);
    end

    // Simulation end
    initial begin
        @(posedge stats1.clocks >= 100);
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
        $finish;
    end
endmodule