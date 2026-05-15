`timescale 1ps/1ps

module tb();
    // Declare variables and wires
    reg clk = 0;
    reg [2:0] sel;
    reg [3:0] data0, data1, data2, data3, data4, data5;
    wire [3:0] out_dut, out_ref;
    logic tb_match, tb_mismatch;
    int errors, errortime, clocks;
    // Parameters for queue display
    localparam MAX_QUEUE_SIZE = 8;
    reg [2:0] sel_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data0_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data1_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data2_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data3_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data4_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] data5_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] out_queue [0:MAX_QUEUE_SIZE-1];
    reg [3:0] expected_queue [0:MAX_QUEUE_SIZE-1];

    // Clock generation
    always #5 clk = ~clk;

    // DUT instantiation
    TopModule dut (
        .sel(sel),
        .data0(data0),
        .data1(data1),
        .data2(data2),
        .data3(data3),
        .data4(data4),
        .data5(data5),
        .out(out_dut)
    );

    // Reference model (combinational logic, no clock needed? Or clock-based if sequential?)
    // Assuming combinational mux; but original may be sequential. Wait, the golden testbench includes RefModule which may have been comb or sequential. Wait in the golden testbench, RefModule has .out(out_ref). If RefModule is a comb mux, then out_ref is comb logic. But the original spec doesn't mention a clock. Wait, the golden testbench's RefModule and DUT (TopModule) are in separate modules. Need to create a reference model that mimics the DUT's behavior. If DUT is comb, then ref is comb. Else, if seq, ref must have same logic.

    // Reference model: Combinational mux
    // If DUT is sequential (has clock?), but original spec says sel, data inputs, outputs. No mention of clock. So likely combinational. Thus, the ref is comb logic.
    // So assign out_ref based on current sel and data inputs.
    // Generate expected output
    always @(*) begin
        if (sel >=0 && sel <=5)
            case (sel)
                0: expected = data0;
                1: expected = data1;
                2: expected = data2;
                3: expected = data3;
                4: expected = data4;
                5: expected = data5;
                default: expected = 0;
            endcase
        else
            expected = 0;
    end
    reg [3:0] expected;

    // Mismatch detection
    always @(posedge clk, negedge clk) begin
        clocks++;
        if (out_dut !== expected) begin
            errors++;
            if (errors == 1) begin
                // Store first mismatch details
                $display("MISMATCH DETECTED AT TIME %t", $time);
                $display("First Mismatch Details:");
                $display("Cycle %0d: sel=%h, data0=%h, data1=%h, data2=%h, data3=%h, data4=%h, data5=%h", $time, sel, data0, data1, data2, data3, data4, data5);
                $display("DUT Output=%h, Expected=%h", out_dut, expected);
            end
        end
    end

    // Simulation controls
    initial begin
        clk = 0;
        errors = 0;
        expected = 0;
        // Initial values
        sel = 0;
        data0 = 4'h0;
        data1 = 4'h1;
        data2 = 4'h2;
        data3 = 4'h3;
        data4 = 4'h4;
        data5 = 4'h5;

        // Test cases
        repeat(10) begin
            sel = $urandom_range(6);
            data0 = $urandom;
            data1 = $urandom;
            data2 = $urandom;
            data3 = $urandom;
            data4 = $urandom;
            data5 = $urandom;
            @(posedge clk);
        end

        // Finish after some time
        #100000 $finish;
    end

    // Final report
    final begin
        if (errors ==0)
            $display("SIMULATION PASSED");
        else
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
    end
endmodule
