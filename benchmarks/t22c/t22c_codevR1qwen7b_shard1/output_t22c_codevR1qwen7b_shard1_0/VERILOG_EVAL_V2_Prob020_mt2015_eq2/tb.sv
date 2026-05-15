// Testbench for TopModule
`timescale 1ps/1ps

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    stats stats1 = '0;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [1:0] A, B;
    logic z_ref, z_dut;
    wire tb_match = ({z_ref} === ({z_ref} ^ {z_dut} ^ {z_ref})); // Correct XOR logic for comparison
    TopModule top_module1 (A, B, z_dut);
    // Reference logic
    assign z_ref = (A == B);
    reg first_time = 0;
    reg [1:0] first_A, first_B;
    reg first_z_ref, first_z_dut;
    // Detect first error
    always @(posedge clk) begin
        if (!stats1.errors && !first_time) begin
            first_time = 1;
            first_A = A;
            first_B = B;
            first_z_ref = z_ref;
            first_z_dut = z_dut;
        end
    end
    // Timeout after 100k cycles
    initial begin #100000 $display("TIMEOUT"); $finish; end
    // Error counting
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (z_ref !== z_dut) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (z_ref !== (z_ref ^ z_dut ^ z_ref)) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z++;
        end
    end
    // Final report
    final begin
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("  First error at time %0d: A=%h, B=%h, Expected z=%b, Actual z=%b", stats1.errortime, first_A, first_B, first_z_ref, first_z_dut);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule