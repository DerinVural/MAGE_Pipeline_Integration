`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input logic clk,
    output logic reset,
    output logic w
);

    initial begin
        repeat(200) @(negedge clk) begin
            reset <= ($random & 'h1f) == 0;
            w <= $random;
        end
        
        #1 $finish;
    end
    
endmodule

module RefModule (
    input logic clk,
    input logic reset,
    input logic w,
    output logic z
);
    typedef enum logic [2:0] {
        STATE_A, STATE_B, STATE_C, STATE_D, STATE_E, STATE_F
    } state_t;

    state_t state, next_state;

    always @(posedge clk) begin
        if (reset) state <= STATE_A;
        else       state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state) 
            STATE_A: next_state = w ? STATE_B : STATE_A;
            STATE_B: next_state = w ? STATE_C : STATE_D;
            STATE_C: next_state = w ? STATE_E : STATE_D;
            STATE_D: next_state = w ? STATE_F : STATE_A;
            STATE_E: next_state = w ? STATE_E : STATE_D;
            STATE_F: next_state = w ? STATE_C : STATE_D;
            default: next_state = STATE_A;
        endcase
    end
    // Based on previous successful logic, z is 1 in states E and F
    assign z = (state == STATE_E || state == STATE_F);
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_z;
        int errortime_z;
        int clocks;
    } stats;
    
    stats stats1;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic reset;
    logic w;
    logic z_ref;
    logic z_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, reset, w, z_ref, z_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk,
        .*,
        .reset,
        .w
    );

    RefModule good1 (
        .clk,
        .reset,
        .w,
        .z(z_ref)
    );
        
    TopModule top_module1 (
        .clk,
        .reset,
        .w,
        .z(z_dut)
    );

    assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
            
            if (stats1.errors == 1) begin
                $display("FIRST MISMATCH DETECTED at time %0t", $time);
                $display("Inputs: clk=%b, reset=%b, w=%b", clk, reset, w);
                $display("Outputs: z_dut=%b, z_ref=%b", z_dut, z_ref);
            end
        end

        if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin 
            if (stats1.errors_z == 0) stats1.errortime_z = $time;
            stats1.errors_z = stats1.errors_z + 1'b1;
        end
    end

    initial begin
        stats1 = '{0, 0, 0, 0, 0};
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

    final begin
        if (stats1.errors > 0 || stats1.errors_z > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", (stats1.errors_z > 0 ? stats1.errors_z : stats1.errors), (stats1.errors_z > 0 ? stats1.errortime_z : stats1.errortime));
        end else begin
            $display("SIMULATION PASSED");
        end

        if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
        else $display("Hint: Output '%s' has no mismatches.", "z");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

endmodule