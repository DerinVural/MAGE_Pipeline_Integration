`timescale 1ps/1ps
module stimulus_gen(input clk, output logic [15:0] in, output logic [511:0] wavedrom_title, output logic wavedrom_enable);
  task wavedrom_start(input [511:0] title = ""); endtask
  task wavedrom_stop; #1; endtask
  always @(posedge clk, negedge clk) in <= $random;
  initial begin
    wavedrom_start("Random inputs");
    repeat(10) @(posedge clk);
    wavedrom_stop();
    repeat(100) @(negedge clk);
    $finish;
  end
endmodule

module tb();
  typedef struct packed {
    int errors;
    int errortime;
    int errors_out_hi;
    int errortime_out_hi;
    int errors_out_lo;
    int errortime_out_lo;
    int clocks;
  } stats;
  stats stats1 = 0;
  wire [511:0] wavedrom_title;
  wire wavedrom_enable;
  reg clk = 0;
  initial forever #5 clk = ~clk;
  logic [15:0] in;
  logic [7:0] out_hi_ref;
  logic [7:0] out_hi_dut;
  logic [7:0] out_lo_ref;
  logic [7:0] out_lo_dut;
  wire tb_match;
  wire tb_mismatch = ~tb_match;
  stimulus_gen stim1(clk, in, wavedrom_title, wavedrom_enable);
  TopModule top_module1(.in(in), .out_hi(out_hi_dut), .out_lo(out_lo_dut));
  assign out_hi_ref = in[15:8];
  assign out_lo_ref = in[7:0];
  assign tb_match = ({out_hi_ref, out_lo_ref} === ({out_hi_ref, out_lo_ref} ^ {out_hi_dut, out_lo_dut} ^ {out_hi_ref, out_lo_ref}));
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(1, stim1, clk, in);
  end
  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (out_hi_ref !== (out_hi_ref ^ out_hi_dut ^ out_hi_ref)) begin
      if (stats1.errors_out_hi == 0) stats1.errortime_out_hi = $time;
      stats1.errors_out_hi++;
    end
    if (out_lo_ref !== (out_lo_ref ^ out_lo_dut ^ out_lo_ref)) begin
      if (stats1.errors_out_lo == 0) stats1.errortime_out_lo = $time;
      stats1.errors_out_lo++;
    end
  end
  initial begin
    #1000000;
    $display("TIMEOUT");
    $finish();
  end
  final begin
    if (stats1.errors_out_hi) begin
      $display("Hint: Output 'out_hi' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out_hi, stats1.errortime_out_hi);
    end else begin
      $display("Hint: Output 'out_hi' has no mismatches");
    end
    if (stats1.errors_out_lo) begin
      $display("Hint: Output 'out_lo' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_out_lo, stats1.errortime_out_lo);
    end else begin
      $display("Hint: Output 'out_lo' has no mismatches");
    end
    $display("Simulation finished at %0d ps", $time);
    if (stats1.errors > 0) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
      $finish;
    end else begin
      $display("SIMULATION PASSED");
    end
  end
endmodule