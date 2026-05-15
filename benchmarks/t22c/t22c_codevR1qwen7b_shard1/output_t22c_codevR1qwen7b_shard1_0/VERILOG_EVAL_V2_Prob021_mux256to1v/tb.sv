`timescale 1ps/1ps
module stimulus_gen (input clk, output logic [1023:0] in, output logic [7:0] sel);
  always @(posedge clk, negedge clk) begin
    for (int i=0; i<32; i++)
      in[i*32 +: 32] <= $random;
    sel <= $random;
  end
endmodule

module tb();
  reg clk = 0;
  initial forever #5 clk = ~clk;

  logic [1023:0] in;
  logic [7:0] sel;
  logic [3:0] out_ref, out_dut;
  wire tb_match, tb_mismatch = ~tb_match;

  TopModule dut(.in(in), .sel(sel), .out(out_dut));
  RefModule gm(.in(in), .sel(sel), .out(out_ref));

  stats stats1;
  initial begin $dumpfile("wave.vcd"); $dumpvars(1, tb); end

  assign tb_match = ({out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}));

  localparam MAX_QUEUE_SIZE = 5;
  reg [1023:0] in_queue [0:MAX_QUEUE_SIZE-1];
  reg [3:0] out_dut_queue [0:MAX_QUEUE_SIZE-1];
  reg [3:0] out_ref_queue [0:MAX_QUEUE_SIZE-1];
  integer queue_ptr = 0, queue_size;

  always @(posedge clk, negedge clk) begin
    if (queue_size >= MAX_QUEUE_SIZE) begin
      queue_ptr = (queue_ptr + 1) % MAX_QUEUE_SIZE;
      queue_size = MAX_QUEUE_SIZE;
    end else begin
      queue_size += 1;
    end
    in_queue[queue_ptr] = in;
    out_dut_queue[queue_ptr] = out_dut;
    out_ref_queue[queue_ptr] = out_ref;

    if (!tb_match) begin
      if (stats1.errors == 0) stats1.errortime = $time;
      stats1.errors += 1;
      if (stats1.errors == 1) begin
        $display(