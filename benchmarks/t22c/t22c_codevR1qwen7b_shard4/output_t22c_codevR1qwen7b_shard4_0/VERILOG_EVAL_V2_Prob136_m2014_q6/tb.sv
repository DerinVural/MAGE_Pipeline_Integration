// Testbench for TopModule
`timescale 1ps/1ps

module stimulus_gen(input clk, output logic reset, output logic w);
    initial begin
        repeat(200) @(posedge clk, negedge clk) begin
            w <= $urandom;
            reset <= ($urandom & 15) == 0;
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    stats stats1 = '{errors:0, errortime:0, errors_z:0, errortime_z:0, clocks:0};
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic reset;
    logic w;
    logic z_ref;
    logic z_dut;
    wire tb_match = ({z_ref} === ({z_ref} ^ {z_dut} ^ {z_ref}));
    RefModule ref_mod(.clk(clk), .reset(reset), .w(w), .z(z_ref));
    TopModule dut(.clk(clk), .reset(reset), .w(w), .z(z_dut));
    wire tb_mismatch = ~tb_match;
    reg strobe = 0;
    task wait_for_timestep;
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask
    stimulus_gen stim(.clk(clk), .*);
    initial begin $dumpfile("wave.vcd"); $dumpvars(1, tb); end
    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (z_ref !== (z_ref ^ z_dut ^ z_ref)) begin
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z++;
        end
    end
    initial begin #1000000 $display("TIMEOUT"); $finish(); end
    final begin
        if (stats1.errors_z) begin
            $display("Hint: Output 'z' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_z, stats1.errortime_z);
        end else begin
            $display("Hint: Output 'z' has no mismatches.");
        end
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
    end
endmodule

module RefModule(input clk, input reset, input w, output logic z);
    // Reference implementation based on state machine description
    // Replace with actual logic from the golden testbench
    localparam STATE_A = 0, STATE_B = 1, STATE_C = 2, STATE_D = 3, STATE_E = 4, STATE_F = 5;
    logic [2:0] state, next_state;
    always @(posedge clk) begin
        if (reset)
            state <= STATE_A;
        else
            state <= next_state;
    end
    always @(*) begin
        case (state)
            STATE_A: next_state = w ? STATE_A : STATE_B;
            STATE_B: next_state = w ? STATE_D : STATE_C;
            STATE_C: next_state = w ? STATE_D : STATE_E;
            STATE_D: next_state = w ? STATE_A : STATE_F;
            STATE_E: next_state = w ? STATE_D : STATE_E;
            STATE_F: next_state = w ? STATE_D : STATE_C;
            default: next_state = STATE_A;
        endcase
    end
    // Output logic for z (assumed based on golden ref)
    assign z = (state == STATE_D || state == STATE_C || state == STATE_E);
endmodule