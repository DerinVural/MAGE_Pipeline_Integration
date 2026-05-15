`timescale 1 ps/1 ps

module RefModule (
    input  logic       clk,
    input  logic       x,
    input  logic [2:0] y,
    output logic       Y0,
    output logic       z
);
    logic [2:0] next_state;
    logic       z_val;

    always_comb begin
        next_state = 3'b000;
        z_val = 1'b0;
        case (y) 
            3'b000: begin
                if (x) next_state = 3'b001; else next_state = 3'b000;
                z_val = 1'b0;
            end
            3'b001: begin
                if (x) next_state = 3'b100; else next_state = 3'b001;
                z_val = 1'b0;
            end
            3'b010: begin
                if (x) next_state = 3'b001; else next_state = 3'b010;
                z_val = 1'b0;
            end
            3'b011: begin
                if (x) next_state = 3'b010; else next_state = 3'b001;
                z_val = 1'b1;
            end
            3'b100: begin
                if (x) next_state = 3'b100; else next_state = 3'b011;
                z_val = 1'b1;
            end
            default: begin
                next_state = 3'b000;
                z_val = 1'b0;
            end
        endcase
    end
    assign Y0 = next_state[0];
    assign z = z_val;
endmodule

module stimulus_gen (
    input  logic       clk,
    output logic       x,
    output logic [2:0] y
);
    initial begin
        repeat(200) @(posedge clk, negedge clk) begin
            y <= $random;
            x <= $random;
        end
        #1 $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_Y0;
        int errortime_Y0;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats_t;

    stats_t stats1;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic x;
    logic [2:0] y;
    logic Y0_ref;
    logic Y0_dut;
    logic z_ref;
    logic z_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, x, y, Y0_ref, Y0_dut, z_ref, z_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;

    stimulus_gen stim1 (
        .clk,
        .x,
        .y
    );

    RefModule good1 (
        .clk,
        .x,
        .y,
        .Y0(Y0_ref),
        .z(z_ref)
    );

    TopModule top_module1 (
        .clk,
        .x,
        .y,
        .Y0(Y0_dut),
        .z(z_dut)
    );

    assign tb_match = ( { Y0_ref, z_ref } === ( { Y0_ref, z_ref } ^ { Y0_dut, z_dut } ^ { Y0_ref, z_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            if (stats1.errors == 1) begin
                $display("Mismatch detected at time %0t:", $time);
                $display("Inputs: x=%b, y=%h (bin=%b)", x, y, y);
                $display("Expected: Y0=%b, z=%b", Y0_ref, z_ref);
                $display("Actual:   Y0=%b, z=%b", Y0_dut, z_dut);
            end
        end

        if (Y0_ref !== ( Y0_ref ^ Y0_dut ^ Y0_ref )) begin
            if (stats1.errors_Y0 == 0) stats1.errortime_Y0 = $time;
            stats1.errors_Y0 = stats1.errors_Y0 + 1'b1;
        end

        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1'b1;
        end
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_Y0) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "Y0", stats1.errors_Y0, stats1.errortime_Y0);
        else $display("Hint: Output '%s' has no mismatches.", "Y0");

        if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output '%s' has no mismatches.", "z");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule