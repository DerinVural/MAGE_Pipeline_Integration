`timescale 1ps/1ps
module tb();
  typedef struct {
    int errors;
    int errortime;
    int errors_sum;
    int errortime_sum;
    int errors_cout;
    int errortime_cout;
    int clocks;
  } stats;
  stats stats1;
  reg clk = 0;
  reg a, b;
  logic sum_ref, sum_dut, cout_ref, cout_dut;
  wire tb_match;
  // Clock generation
  initial forever #5 clk = ~clk;
  // Stimulus
  stimulus_gen stim1 (clk, a, b);
  RefModule good1 (.a(a), .b(b), .sum(sum_ref), .cout(cout_ref));
  TopModule dut (.a(a), .b(b), .sum(sum_dut), .cout(cout_dut));
  // Check mismatches
  assign tb_match = ({sum_ref, cout_ref} === ({sum_ref, cout_ref} ^ {sum_dut, cout_dut} ^ {sum_ref, cout_ref}));
  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (sum_ref !== sum_ref ^ sum_dut ^ sum_ref) begin
      if (stats1.errors_sum == 0) stats1.errortime_sum = $time;
      stats1.errors_sum++;
    end
    if (cout_ref !== cout_ref ^ cout_dut ^ cout_ref) begin
      if (stats1.errors_cout == 0) stats1.errortime_cout = $time;
      stats1.errors_cout++;
    end
  end
  // Timeout
  initial begin #1000000 $display("TIMEOUT"); $finish; end
  // Simulation end
  final begin
    if (stats1.errors > 0) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
      $display("First Mismatch at time %0d: a=%b, b=%b; Expected sum=%b, cout=%b; Got sum=%b, cout=%b", stats1.errortime, a, b, sum_ref, cout_ref, sum_dut, cout_dut);
    end else begin
      $display("SIMULATION PASSED");
    end
  end
endmodule
module stimulus_gen (input clk, output logic a, output logic b);
  always @(posedge clk, negedge clk) {a,b} <= $urandom;
  initial repeat(100) @(negedge clk) $finish;
endmodule