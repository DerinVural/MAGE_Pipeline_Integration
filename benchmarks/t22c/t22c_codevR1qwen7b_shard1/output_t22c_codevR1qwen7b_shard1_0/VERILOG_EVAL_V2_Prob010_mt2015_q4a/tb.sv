`timescale 1ps/1ps

module stimulus_gen (input clk, output x, output y);
  reg x, y;
  @ (posedge clk)
  begin
    {x, y} = $random % 4;
  end
endmodule

module tb();
  typedef struct packed {
    integer errors;
    integer errortime;
    integer errors_z;
    integer errortime_z;
    integer clocks;
  } stats;
  stats stats1 = '{errors:0, errortime:0, errors_z:0, errortime_z:0, clocks:0};
  reg clk = 0;
  initial forever #5 clk = ~clk;
  logic x;
  logic y;
  logic z_dut, z_ref;
  stimulus_gen stim (
    .clk(clk),
    .x(x),
    .y(y)
  );
  TopModule dut (
    .x(x),
    .y(y),
    .z(z_dut)
  );
  RefModule ref (
    .x(x),
    .y(y),
    .z(z_ref)
  );
  wire match = (z_dut === z_ref);
  always @(posedge clk) begin
    stats1.clocks += 1;
    if (!match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors += 1;
    end
    if (z_dut !== ((x ^ y) & x)) begin
      if (stats1.errors_z == 0) stats1.errortime_z = $time;
      stats1.errors_z += 1;
    end
  end
  integer error_count;
  integer total_errors;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(1, tb, x, y, z_dut, z_ref, clk);
  end
  final begin
    error_count = stats1.errors + stats1.errors_z;
    total_errors = stats1.errors ? stats1.errors : stats1.errors_z;
    if (error_count > 0) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", error_count, stats1.errortime);
      if (stats1.errors > 0) begin
        $display("First x mismatch at time %0d: x=%b, y=%b, z_dut=%b, z_ref=%b", stats1.errortime, x, y, z_dut, z_ref);
      end else begin
        $display("First z mismatch at time %0d: x=%b, y=%b, z_dut=%b, z_ref=%b", stats1.errortime_z, x, y, z_dut, z_ref);
      end
    end else begin
      $display("SIMULATION PASSED");
    end
  end
endmodule