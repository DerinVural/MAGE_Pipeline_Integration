`timescale 1ps/1ps

module stimulus_gen(); // Not used, but golden testbench might include tasks.
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_outv;
        int errortime_outv;
        int errors_o2;
        int errortime_o2;
        int errors_o1;
        int errortime_o1;
        int errors_o0;
        int errortime_o0;
        int clocks;
    } stats;

    stats stats1 = '0;
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [2:0] vec;
    logic [2:0] outv_ref, outv_dut;
    logic o2_ref, o2_dut;
    logic o1_ref, o1_dut;
    logic o0_ref, o0_dut;

    // Reference module instance
    RefModule ref_inst (
        .vec(vec),
        .outv(outv_ref),
        .o2(o2_ref),
        .o1(o1_ref),
        .o0(o0_ref)
    );

    // DUT instance
    TopModule top_module_inst (
        .vec(vec),
        .outv(outv_dut),
        .o2(o2_dut),
        .o1(o1_dut),
        .o0(o0_dut)
    );

    // Comparison logic
    wire tb_match;
    assign tb_match = ( {outv_ref, o2_ref, o1_ref, o0_ref} === ({outv_ref, o2_ref, o1_ref, o0_ref} ^ {outv_dut, o2_dut, o1_dut, o0_dut} ^ {outv_ref, o2_ref, o1_ref, o0_ref}) );

    // Error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (outv_ref !== (outv_ref ^ outv_dut ^ outv_ref)) begin
            if (stats1.errors_outv == 0) stats1.errortime_outv = $time;
            stats1.errors_outv++;
        end
        if (o2_ref !== (o2_ref ^ o2_dut ^ o2_ref)) begin
            if (stats1.errors_o2 == 0) stats1.errortime_o2 = $time;
            stats1.errors_o2++;
        end
        if (o1_ref !== (o1_ref ^ o1_dut ^ o1_ref)) begin
            if (stats1.errors_o1 == 0) stats1.errortime_o1 = $time;
            stats1.errors_o1++;
        end
        if (o0_ref !== (o0_ref ^ o0_dut ^ o0_ref)) begin
            if (stats1.errors_o0 == 0) stats1.errortime_o0 = $time;
            stats1.errors_o0++;
        end
    end

    // Stimulus
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, vec, outv_ref, outv_dut, o2_ref, o2_dut, o1_ref, o1_dut, o0_ref, o0_dut);
        vec = 0;
        repeat(10) @(posedge clk);
        vec = 3'b111;
        repeat(10) @(posedge clk);
        #1 $finish;
    end

    // Simulation end check
    final begin
        if (stats1.errors_outv) $display("Hint: Output 'outv' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_outv, stats1.errortime_outv);
        else $display("Hint: Output 'outv' has no mismatches.");
        if (stats1.errors_o2) $display("Hint: Output 'o2' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_o2, stats1.errortime_o2);
        else $display("Hint: Output 'o2' has no mismatches.");
        if (stats1.errors_o1) $display("Hint: Output 'o1' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_o1, stats1.errortime_o1);
        else $display("Hint: Output 'o1' has no mismatches.");
        if (stats1.errors_o0) $display("Hint: Output 'o0' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_o0, stats1.errortime_o0);
        else $display("Hint: Output 'o0' has no mismatches.");
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            // Display first error details
            if (stats1.errors_outv > 0) begin
                $display("First mismatch in outv at time %0d: expected %h%b, got %h%b",
                    stats1.errortime_outv,
                    outv_ref, outv_ref,
                    outv_dut, outv_dut);
            end else if (stats1.errors_o2 > 0) begin
                $display("First mismatch in o2 at time %0d: expected %h%b, got %h%b",
                    stats1.errortime_o2,
                    o2_ref, o2_ref,
                    o2_dut, o2_dut);
            end else if (stats1.errors_o1 > 0) begin
                $display("First mismatch in o1 at time %0d: expected %h%b, got %h%b",
                    stats1.errortime_o1,
                    o1_ref, o1_ref,
                    o1_dut, o1_dut);
            end else if (stats1.errors_o0 > 0) begin
                $display("First mismatch in o0 at time %0d: expected %h%b, got %h%b",
                    stats1.errortime_o0,
                    o0_ref, o0_ref,
                    o0_dut, o0_dut);
            end else begin
                $display("First mismatch in outv at time %0d: expected %h%b, got %h%b",
                    stats1.errortime,
                    outv_ref, outv_ref,
                    outv_dut, outv_dut);
            end
        end else begin
            $display("SIMULATION PASSED");
        end
    end

    // Timeout after 1 million cycles
    initial begin
        #1000000 $display("TIMEOUT"); $finish();
    end
endmodule