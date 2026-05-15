`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
  input clk,
  output logic reset,
  output logic s, w,
  input tb_match
);
  bit spulse_fail = 0;
  bit failed = 0;
  always @(posedge clk, negedge clk)
    if (!tb_match) failed = 1;
  initial begin
    reset <= 1;
    s <= 0;
    w <= 0;
    @(posedge clk);
    @(posedge clk);
    reset <= 0;
    @(posedge clk);
    @(posedge clk);
    s <= 1;
    repeat(200) @(posedge clk, negedge clk) begin
      w <= $random;
    end
    reset <= 1;
    @(posedge clk);
    reset <= 0;
    @(posedge clk);
    @(posedge clk);
    repeat(200) @(posedge clk, negedge clk) begin
      w <= $random;
    end
    @(posedge clk)
      spulse_fail <= failed;
    repeat(500) @(negedge clk) begin
      reset <= !($random & 63);
      s <= !($random & 7);
      w <= $random;
    end
    if (failed && !spulse_fail) begin
      $display("Hint: Your state machine should ignore input 's' after the state A to B transition.");
    end
    #1 $finish;
  end
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
  wire[511:0] wavedrom_title;
  wire wavedrom_enable;
  int wavedrom_hide_after_time;
  reg clk = 0;
  initial forever
    #5 clk = ~clk;
  logic reset;
  logic s;
  logic w;
  logic z_ref;
  logic z_dut;
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,s,w,z_ref,z_dut );
  end
  wire tb_match;
  wire tb_mismatch = ~tb_match;
  stimulus_gen stim1 (
    .clk(clk),
    .*,
    .reset(reset),
    .s(s),
    .w(w) 
  );
  RefModule good1 (
    .clk(clk),
    .reset(reset),
    .s(s),
    .w(w),
    .z(z_ref) 
  );
  TopModule top_module1 (
    .clk(clk),
    .reset(reset),
    .s(s),
    .w(w),
    .z(z_dut) 
  );
  bit strobe = 0;
  task wait_for_end_of_timestep;
    repeat(5) begin
      strobe <= !strobe;
      @(strobe);
    end
  endtask
  final begin
    if (stats1.errors_z) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "z", stats1.errors_z, stats1.errortime_z);
    else $display("Hint: Output '%s' has no mismatches.", "z");
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    if (stats1.errors + stats1.errors_z > 0) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors + stats1.errors_z, stats1.errortime);
    end else begin
      $display("SIMULATION PASSED");
    end
  end
  assign tb_match = ( { z_ref } === ( { z_ref } ^ { z_dut } ^ { z_ref } ) );
  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (z_ref !== ( z_ref ^ z_dut ^ z_ref ))
    begin if (stats1.errors_z == 0) stats1.errortime_z = $time;
      stats1.errors_z = stats1.errors_z+1'b1; end
  end
  initial begin
    #1000000;
    $display("TIMEOUT");
    $finish();
  end
endmodule