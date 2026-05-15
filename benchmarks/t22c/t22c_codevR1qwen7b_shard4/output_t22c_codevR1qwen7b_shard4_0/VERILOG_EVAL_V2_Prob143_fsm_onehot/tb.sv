 `timescale 1ps/1ps
module stimulus_gen (input clk, output logic in, output logic [9:0] state);
    reg [9:0] state_error = 0;
    initial begin
        repeat(2) @(posedge clk);
        forever @(posedge clk, negedge clk) state_error <= state_error | (next_state_ref ^ next_state_dut);
    end
    initial begin
        state = 0;
        in = 0;
        @(negedge clk);
        for (int i = 0; i < 10; i++) begin
            @(negedge clk, posedge clk);
            state = 1 << i;
            in = 0;
        end
        for (int i = 0; i < 10; i++) begin
            @(negedge clk, posedge clk);
            state = 1 << i;
            in = 1;
        end
        @(negedge clk);
        repeat(200) @(posedge clk, negedge clk) begin
            state = 1 << ($unsigned($random) % 10);
            in = $random;
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
        int errors_out1;
        int errortime_out1;
        int errors_out2;
        int errortime_out2;
        int clocks;
    } stats;
    stats stats1 = '0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic in;
    logic [9:0] state;
    logic [9:0] next_state_ref;
    logic [9:0] next_state_dut;
    logic out1_ref;
    logic out1_dut;
    logic out2_ref;
    logic out2_dut;
    wire tb_match, tb_mismatch;
    assign tb_match = ({next_state_ref, out1_ref, out2_ref} === ({next_state_ref, out1_ref, out2_ref} ^ {next_state_dut, out1_dut, out2_dut} ^ {next_state_ref, out1_ref, out2_ref}));
    assign tb_mismatch = ~tb_match;
    stimulus_gen stim1 (.clk(clk), .in(in), .state(state));
    RefModule good1 (.in(in), .state(state), .next_state(next_state_ref), .out1(out1_ref), .out2(out2_ref));
    TopModule top_module1 (.in(in), .state(state), .next_state(next_state_dut), .out1(out1_dut), .out2(out2_dut));
    bit strobe = 0;
    task wait_for_end_of_timestep(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (next_state_ref !== (next_state_ref ^ next_state_dut ^ next_state_ref)) begin
            if (stats1.errors_next_state == 0) stats1.errortime_next_state = $time;
            stats1.errors_next_state++;
        end
        if (out1_ref !== (out1_ref ^ out1_dut ^ out1_ref)) begin
            if (stats1.errors_out1 == 0) stats1.errortime_out1 = $time;
            stats1.errors_out1++;
        end
        if (out2_ref !== (out2_ref ^ out2_dut ^ out2_ref)) begin
            if (stats1.errors_out2 == 0) stats1.errortime_out2 = $time;
            stats1.errors_out2++;
        end
    end
    initial begin
        if (stats1.errors_next_state) $display("Hint: Output 'next_state' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_next_state, stats1.errortime_next_state);
        else $display("Hint: Output 'next_state' has no mismatches.");
        if (stats1.errors_out1) $display("Hint: Output 'out1' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out1, stats1.errortime_out1);
        else $display("Hint: Output 'out1' has no mismatches.");
        if (stats1.errors_out2) $display("Hint: Output 'out2' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out2, stats1.errortime_out2);
        else $display("Hint: Output 'out2' has no mismatches.");
        $display("Hint: Total mismatched samples is %0d out of %0d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end
        #1 $finish;
    end
    initial begin #1000000; $display("TIMEOUT"); $finish; end
endmodule