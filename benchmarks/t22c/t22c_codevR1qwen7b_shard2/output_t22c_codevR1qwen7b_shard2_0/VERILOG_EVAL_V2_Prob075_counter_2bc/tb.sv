`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen(
    input clk,
    output logic areset,
    output logic train_valid,
    output logic train_taken,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    output logic wavedrom_hide_after_time,
    input tb_match,
    input tb_mismatch,
    input [1:0] state_ref,
    input [1:0] state_dut,
    input tb_mismatch_state
);
    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    reg reset;
    task reset_test(input async=0); bit arfail, srfail, datafail; @(posedge clk); @(posedge clk) reset <= 0; repeat(3) @(posedge clk); @(negedge clk) begin datafail = !tb_match; reset <= 1; end @(posedge clk) arfail = !tb_match; @(posedge clk) begin srfail = !tb_match; reset <= 0; end if (srfail) $display("Hint: Your reset doesn't seem to be working."); else if (arfail && (async || !datafail)) $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous"); endtask assign areset = reset; logic train_taken_r; assign train_taken = train_valid ? train_taken_r : 1'bx;
    initial begin
        @(posedge clk); @(posedge clk) reset <= 1; @(posedge clk) reset <= 0; train_taken_r <= 1; train_valid <= 1; wavedrom_start("Asynchronous reset"); reset_test(1); wavedrom_stop(); @(posedge clk) reset <= 1; train_taken_r <= 1; train_valid <= 0; @(posedge clk) reset <= 0; wavedrom_start("Count up, then down"); train_taken_r <= 0; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 0; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 0; @(posedge clk) train_valid <= 1; train_taken_r <= 0; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 0; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 1; @(posedge clk) train_valid <= 0; @(posedge clk) train_valid <= 1; repeat(1000) @(posedge clk, negedge clk) {train_valid, train_taken_r} <= {$urandom}; #1 $finish; end endmodule
module tb();
    typedef struct packed { int errors; int errortime; int errors_state; int errortime_state; int clocks; } stats;
    stats stats1;
    wire [511:0] wavedrom_title; wire wavedrom_enable; int wavedrom_hide_after_time;
    reg clk=0; initial forever #5 clk = ~clk;
    logic areset; logic train_valid; logic train_taken; logic [1:0] state_ref; logic [1:0] state_dut;
    initial begin $dumpfile("wave.vcd"); $dumpvars(1, stim1.clk, tb_mismatch, clk, areset, train_valid, train_taken, state_ref, state_dut); end
    wire tb_match; wire tb_mismatch = ~tb_match; stimulus_gen stim1( .clk(clk), .areset(areset), .train_valid(train_valid), .train_taken(train_taken), .wavedrom_title(wavedrom_title), .wavedrom_enable(wavedrom_enable), .wavedrom_hide_after_time(wavedrom_hide_after_time) ); RefModule good1( .clk(clk), .areset(areset), .train_valid(train_valid), .train_taken(train_taken), .state(state_ref) ); TopModule top_module1( .clk(clk), .areset(areset), .train_valid(train_valid), .train_taken(train_taken), .state(state_dut) ); bit strobe=0; task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask final begin if (stats1.errors_state) $display("Hint: Output 'state' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_state, stats1.errortime_state); else $display("SIMULATION PASSED"); $display("Simulation finished at %0d ps", $time); $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks); end
    assign tb_match = ( { state_ref } === ( { state_ref } ^ { state_dut } ^ { state_ref } ) ); always @(posedge clk, negedge clk) begin stats1.clocks++; if (!tb_match) begin if (stats1.errors == 0) stats1.errortime = $time; stats1.errors++; end if (state_ref !== ( state_ref ^ state_dut ^ state_ref )) begin if (stats1.errors_state == 0) stats1.errortime_state = $time; stats1.errors_state += 1; end end initial #1000000 $finish; endmodule