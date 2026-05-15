module stimulus_gen(clk, a, b, c, d);
  input clk;
  output reg a,b,c,d;
  task wavedrom_start(); endtask
  task wavedrom_stop(); endtask
  initial begin
    {a,b,c,d} = 4'h0;
    @(negedge clk);
    wavedrom_start();
    repeat(20) @(posedge clk, negedge clk) {d,c,b,a} <= {d,c,b,a} + 1;
    wavedrom_stop();
    repeat(100) @(posedge clk, negedge clk) {a,b,c,d} <= $random;
    #1 $finish;
  end
endmodule

module tb();
  reg clk = 0;
  reg a,b,c,d;
  wire out, out_n;
  reg out_ref, out_n_ref;
  reg [31:0] errors, errortime, errors_out, errortime_out, errors_out_n, errortime_out_n, clocks;
  reg [63:0] sample_count;
  initial begin
    clk = 0;
    errors = 0; errors_out = 0; errors_out_n = 0;
    errortime = 0; errortime_out = 0; errortime_out_n = 0;
    clocks = 0;
    a = 0; b = 0; c = 0; d = 0;
    #10;
    for (int i = 0; i < 8; i++) begin
      a = i[3]; b = i[2]; c = i[1]; d = i[0]; #10;
    end
    #1000 $finish;
  end
  always @(posedge clk, negedge clk) begin
    clocks++;
    if (out !== out_ref) errors++;
    if (out !== out_ref) errors_out++;
    if (out_n !== out_n_ref) errors_out_n++;
    if (errors == 0) errortime = $time;
    if (errors_out == 0) errortime_out = $time;
    if (errors_out_n == 0) errortime_out_n = $time;
  end
  TopModule dut(a,b,c,d, out, out_n);
  RefModule ref_mod(a,b,c,d, out_ref, out_n_ref);
  initial begin
    #100000 $display("TIMEOUT"); $finish;
  end
  final begin
    if (errors) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
    else $display("SIMULATION PASSED");
  end
endmodule

module RefModule(input a, input b, input c, input d, output out, output out_n);
  wire and1 = a & b;
  wire and2 = c & d;
  wire or_out = and1 | and2;
  assign out = or_out;
  assign out_n = ~or_out;
endmodule