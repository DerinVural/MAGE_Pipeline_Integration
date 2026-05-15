`timescale 1ps/1ps
module stimulus_gen(clk, reset, x);
  input clk;
  output logic reset;
  output logic x;

  initial begin
    reset = 1;
    x = 0;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    @(posedge clk);
    @(posedge clk);
    repeat(500) @(negedge clk) begin
      reset <= !($random & 63);
      x <= $random;
    end
    #1 $finish;
  end
endmodule

module tb();
  typedef struct packed { int errors; int errortime; int errors_z; int errortime_z; int clocks; } stats_t;
  stats_t stats1 = '0;

  reg clk = 0;
  initial forever #5 clk = ~clk;

  logic reset;
  logic x;
  logic z_ref;
  logic z_dut;

  wire tb_match;
  assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );

  // Instantiate modules
  TopModule top_module1 ( .clk(clk), .reset(reset), .x(x), .z(z_dut) );
  RefModule good1 ( .clk(clk), .reset(reset), .x(x), .z(z_ref) );

  // Statistics tracking
  reg strobe = 0;
  task wait_for_timestep; endtask // Adjust as needed for synthesis, but not part of the simulation logic

  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (z_ref !== ( z_ref ^ z_dut ^ z_ref )) begin
      if (stats1.errors_z == 0) stats1.errortime_z = $time;
      stats1.errors_z++;
    end
  end

  // Simulation control
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(1, tb, clk, reset, x, z_ref, z_dut);
  end

  initial begin
    #1000000; // Timeout after 1e6 time units
    $display("TIMEOUT");
    $finish;
  end

  final begin
    if (stats1.errors_z)
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_z, stats1.errortime_z);
    else
      $display("SIMULATION PASSED");

    $display("Total mismatched samples: %0d out of %0d", stats1.errors, stats1.clocks);
  end
endmodule