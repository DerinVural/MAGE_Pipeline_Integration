`timescale 1ps/1ps

module stimulus_gen (input clk, output logic in, output logic [1:0] state);
    initial begin
        repeat(100) @(posedge clk, negedge clk) begin
            in <= $random;
            state <= $random;
        end
        #1 $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_next_state;
        int errortime_next_state;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;

    stats stats1;
    wire clk = 0;
    initial forever #5 clk = ~clk;
    logic in;
    logic [1:0] state;
    logic [1:0] next_state_ref, next_state_dut;
    logic out_ref, out_dut;
    RefModule ref1 (.in(in), .state(state), .next_state(next_state_ref), .out(out_ref));
    TopModule top1 (.in(in), .state(state), .next_state(next_state_dut), .out(out_dut));
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1);
    end
    wire tb_match = (next_state_ref === next_state_dut) && (out_ref === out_dut);
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            stats1.errors++;
            if (stats1.errors == 1) stats1.errortime = $time;
        end
        if (next_state_ref !== next_state_dut) begin
            stats1.errors_next_state++;
            if (stats1.errortime_next_state == 0) stats1.errortime_next_state = $time;
        end
        if (out_ref !== out_dut) begin
            stats1.errors_out++;
            if (stats1.errortime_out == 0) stats1.errortime_out = $time;
        end
    end
    initial begin
        #1000000 $display("TIMEOUT"); $finish;
    end
    initial begin
        stats1.errors = stats1.errors_next_state + stats1.errors_out;
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, (stats1.errortime_next_state ? stats1.errortime_next_state : stats1.errortime_out));
        end else begin
            $display("SIMULATION PASSED");
        end
        $finish;
    end
endmodule

module RefModule (input in, input [1:0] state, output [1:0] next_state, output out);
    localparam [1:0] A=0, B=1, C=2, D=3;
    reg [1:0] next_state;
    reg out;
    always @(*) begin
        case (state)
            A: out = 0;
            B: out = 0;
            C: out = 0;
            D: out = 1;
            default: out = 0;
        endcase
    end
    always @(*) begin
        case (state)
            A: next_state = in ? B : A;
            B: next_state = in ? B : C;
            C: next_state = in ? D : A;
            D: next_state = in ? B : C;
            default: next_state = A;
        endcase
    end
endmodule