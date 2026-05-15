`timescale 1ps/1ps

module stimulus_gen (input clk, output reg L, output reg r_in, output reg q_in);
  always @(posedge clk, negedge clk) {L, r_in, q_in} = $random % 8;
  initial begin
    repeat(100) @(posedge clk);
    #1 $finish;
  end
endmodule

module tb();
  reg clk = 0;
  initial forever #5 clk = ~clk;

  reg L, r_in, q_in;
  reg Q_ref, Q_dut;

  wire tb_match, tb_mismatch;
  assign tb_mismatch = ~tb_match;

  stimulus_gen stim1 (clk, L, r_in, q_in);

  RefModule good1 (clk, L, q_in, r_in, Q_ref);
  TopModule top_module1 (clk, L, q_in, r_in, Q_dut);

  typedef struct packed {
    int errors;
    int errortime;
    int errors_Q;
    int errortime_Q;
    int clocks;
  } stats;
  stats stats1 = {0, 0, 0, 0, 0};

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(1, clk, L, q_in, r_in, Q_ref, Q_dut);
  end

  assign tb_match = (Q_ref === (Q_ref ^ Q_dut ^ Q_ref));

  always @(posedge clk, negedge clk) begin
    stats1.clocks = stats1.clocks + 1;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors = stats1.errors + 1;
    end
    if (Q_ref !== (Q_ref ^ Q_dut ^ Q_ref)) begin
      if (stats1.errors_Q == 0) stats1.errortime_Q = $time;
      stats1.errors_Q = stats1.errors_Q + 1;
    end
  end

  initial begin #1000000 $finish; end

  final begin
    if (stats1.errors_Q) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_Q, stats1.errortime_Q);
    end else begin
      $display("SIMULATION PASSED");
    end
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
  end
endmodule