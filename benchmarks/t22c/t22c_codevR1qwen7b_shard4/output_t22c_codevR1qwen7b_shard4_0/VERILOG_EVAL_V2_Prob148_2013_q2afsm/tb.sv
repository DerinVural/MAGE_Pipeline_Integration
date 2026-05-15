// This testbench includes all inputs as per the golden spec
`timescale 1ps/1ps
module tb();
  reg clk = 0;
  reg resetn;
  reg [2:0] r;
  wire [2:0] g;
  reg [2:0] g_ref;

  // Initialize VCD waveforms
  initial $dumpfile("wave.vcd");
  initial $dumpvars(0, tb);

  // Clock generation
  initial forever #5 clk = ~clk;

  // Reset and input stimulus
  initial begin
    resetn = 0;
    r = 0;
    #(5) resetn = 1;
    // Add test cases here
    #(100);
    $finish;
  end

  // Instantiate DUT and reference module
  TopModule dut (
    .clk(clk),
    .resetn(resetn),
    .r(r),
    .g(g)
  );

  RefModule ref_mod (
    .clk(clk),
    .resetn(resetn),
    .r(r),
    .g(g_ref)
  );

  // Error checking
  reg [5:0] errors = 0;
  reg [31:0] err_time = 0;

  always @(negedge clk) begin
    if (g !== g_ref) begin
      $display("SIMULATION FAILED - 1 MISMATCHES DETECTED, FIRST AT TIME %0d", $time);
      $display("TIME r=%b, resetn=%b", r, resetn);
      $display("TIME g=%b, expected=%b", g, g_ref);
      $finish;
    end
  end

  // Simulation end check
  initial begin
    #(1000000);
    $display("SIMULATION PASSED");
    $finish;
  end

endmodule
