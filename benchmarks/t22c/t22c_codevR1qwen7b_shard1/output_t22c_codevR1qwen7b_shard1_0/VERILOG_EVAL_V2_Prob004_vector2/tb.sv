`timescale 1ps/1ps
module tb();
  reg clk = 0;
  initial forever #5 clk = ~clk;
  logic [31:0] in;
  logic [31:0] out_ref, out_dut;
  // Queue logic for first mismatch display
  reg [31:0] input_queue [0:4];
  reg [31:0] got_output_queue [0:4];
  reg [31:0] golden_queue [0:4];
  reg [0:4] reset_queue;
  localparam MAX_QUEUE_SIZE = 5;
  integer cnt;
  // Assume stimulus_gen's in is driven by $random in testbench
  // Instantiate module
  TopModule dut(.in(in), .out(out_dut));
  // Assume RefModule for golden output
  RefModule golden_dut(.in(in), .out(out_ref));
  // Check on clock edges
  always @(posedge clk, negedge clk) begin
    if (out_dut !== out_ref) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors +=1;
    end
    // Queue management
    for (cnt = 0; cnt < MAX_QUEUE_SIZE-1; cnt = cnt +1) begin
      input_queue[cnt] = input_queue[cnt+1];
      got_output_queue[cnt] = got_output_queue[cnt+1];
      golden_queue[cnt] = golden_queue[cnt+1];
      reset_queue[cnt] = reset_queue[cnt+1];
    end
    input_queue[MAX_QUEUE_SIZE-1] = in;
    got_output_queue[MAX_QUEUE_SIZE-1] = out_dut;
    golden_queue[MAX_QUEUE_SIZE-1] = out_ref;
    reset_queue[MAX_QUEUE_SIZE-1] = 0;
    // First mismatch detection
    if (out_dut !== out_ref && stats1.errors ==0) begin
      $display("First Mismatch Detected at time %t", $time);
      for (int i =0; i < MAX_QUEUE_SIZE; i =i+1) begin
        $display("Cycle %0d: Input %h, Got %h, Expected %h", i, input_queue[i], got_output_queue[i], golden_queue[i]);
      end
    end
  end
  // Simulation end handling
  integer errors;
  initial begin
    errors = 0;
    // Wait for simulation end
    wait ($finish);
    if (errors) begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME TBA", errors);
    end else begin
      $display("SIMULATION PASSED");
    end
  end
endmodule