module stimulus_gen( input clk, output reg x3, x2, x1 );
  initial begin
    {x3, x2, x1} <= 3'b000;
    @(negedge clk);
    repeat(8) @(posedge clk) {x3, x2, x1} <= {x3, x2, x1} + 1;
  end
endmodule

module tb();
  reg clk;
  logic x3, x2, x1;
  logic f_ref, f_dut;
  typedef struct packed {
    int errors;
    int errortime;
    int errors_f;
    int errortime_f;
    int clocks;
  } stats;
  stats stats1;
  wire [511:0] wavedrom_title;
  wire wavedrom_enable;

  initial forever #5 clk = ~clk;

  stimulus_gen stim1( .clk(clk), .x3(x3), .x2(x2), .x1(x1) );
  RefModule good1( .x3(x3), .x2(x2), .x1(x1), .f(f_ref) );
  TopModule top_module1( .x3(x3), .x2(x2), .x1(x1), .f(f_dut) );

  wire tb_match = ( {f_ref} === ( {f_ref} ^ {f_dut} ^ {f_ref} ) );

  always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors++;
    end
    if (f_ref !== ( f_ref ^ f_dut ^ f_ref )) begin
      if (stats1.errors_f == 0) stats1.errortime_f = $time;
      stats1.errors_f++;
    end
  end

  initial begin
    #1000; $display("TIMEOUT"); $finish;
  end

  final begin
    if (stats1.errors_f) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_f, stats1.errortime_f);
    end else begin
      $display("SIMULATION PASSED");
    end
    $finish;
  end
endmodule

module RefModule( input x3, x2, x1, output f );
  assign f = ( (x3 & x2) | (~x3 & (x2 ^ x1)) );
endmodule

module TopModule( input x3, x2, x1, output f );
  always @(*) begin
    case({x3, x2, x1})
      3'b000: f = 0;
      3'b001: f = 0;
      3'b010: f = 1;
      3'b011: f = 1;
      3'b100: f = 0;
      3'b101: f = 1;
      3'b110: f = 0;
      3'b111: f = 1;
    endcase
  end
endmodule