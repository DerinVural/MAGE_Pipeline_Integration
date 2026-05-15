`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13
module stimulus_gen (
	input clk,
	output logic a,b,cin,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable);
task wavedrom_start(input[511:0] title = ""); endtask task wavedrom_stop; #1; endtask initial begin wavedrom_start(); @(posedge clk) {a,b,cin} <= 3'b000; @(posedge clk) {a,b,cin} <= 3'b010; @(posedge clk) {a,b,cin} <= 3'b100; @(posedge clk) {a,b,cin} <= 3'b110; @(posedge clk) {a,b,cin} <= 3'b000; @(posedge clk) {a,b,cin} <= 3'b001; @(posedge clk) {a,b,cin} <= 3'b011; @(negedge clk) wavedrom_stop(); repeat(200) @(posedge clk, negedge clk) {a,b,cin} <= $random; $finish; endendmodule module tb(); typedef struct packed {
	int errors;
	int errortime;
	int errors_cout;
	int errortime_cout;
	int errors_sum;
	int errortime_sum;
	int clocks;
} stats; stats stats1; wire[511:0] wavedrom_title; wire wavedrom_enable; int wavedrom_hide_after_time; reg clk=0; initial forever #5 clk = ~clk; logic a; logic b; logic cin; logic cout_ref; logic cout_dut; logic sum_ref; logic sum_dut; initial begin $dumpfile("wave.vcd"); $dumpvars(1, stim1.clk, tb_mismatch ,a,b,cin,cout_ref,cout_dut,sum_ref,sum_dut ); end wire tb_match; wire tb_mismatch = ~tb_match; stimulus_gen stim1 (.clk, .a(a), .b(b), .cin(cin)); RefModule good1 (.a(a), .b(b), .cin(cin), .cout(cout_ref), .sum(sum_ref)); TopModule top_module1 (.a(a), .b(b), .cin(cin), .cout(cout_dut), .sum(sum_dut)); bit strobe = 0; task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask final begin if (stats1.errors_cout) $display("Hint: Output 'cout' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_cout, stats1.errortime_cout); else $display("Hint: Output 'cout' has no mismatches."); if (stats1.errors_sum) $display("Hint: Output 'sum' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_sum, stats1.errortime_sum); else $display("Hint: Output 'sum' has no mismatches."); $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks); $display("Simulation finished at %0d ps", $time); $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks); if (stats1.errors == 0) $display("SIMULATION PASSED"); else $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime); end assign tb_match = ( { cout_ref, sum_ref } === ( { cout_ref, sum_ref } ^ { cout_dut, sum_dut } ^ { cout_ref, sum_ref } ) ); always @(posedge clk, negedge clk) begin stats1.clocks++; if (!tb_match) begin if (stats1.errors == 0) stats1.errortime = $time; stats1.errors++; end if (cout_ref !== ( cout_ref ^ cout_dut ^ cout_ref )) begin if (stats1.errors_cout == 0) stats1.errortime_cout = $time; stats1.errors_cout = stats1.errors_cout+1'b1; end if (sum_ref !== ( sum_ref ^ sum_dut ^ sum_ref )) begin if (stats1.errors_sum == 0) stats1.errortime_sum = $time; stats1.errors_sum = stats1.errors_sum+1'b1; end end initial begin #1000000 $display("TIMEOUT"); $finish(); end endmodule