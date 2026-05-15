`timescale 1ps/1ps
module tb();
  reg clk = 0;
  reg in;
  reg [3:0] state;
  wire [3:0] next_state;
  wire out;

  // Instantiate the DUT
  TopModule dut (
    .in(in),
    .state(state),
    .next_state(next_state),
    .out(out)
  );

  // Golden model signals
  reg [3:0] next_state_golden;
  reg out_golden;

  // Trigger clock
  always #5 clk = ~clk;

  // Stimulus generation
  initial begin
    // Initialize signals
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    clk = 0;
    in = 0;
    state = 4'b0001; // Initial state A
    // Timing variables
    integer time_counter = 0;
    integer error_count = 0;
    integer error_time = 0;
    integer i;
    // Simulation duration
    repeat(40) @(posedge clk);
    #10 $finish;
  end

  // Simulation check
  always @(posedge clk, negedge clk) begin
    // Golden model logic
    case (state)
      4'b0001: begin // State A
        next_state_golden = (in == 0) ? 4'b0001 : 4'b0010;
        out_golden = 0;
      end
      4'b0010: begin // State B
        next_state_golden = (in == 0) ? 4'b0100 : 4'b0010;
        out_golden = 0;
      end
      4'b0100: begin // State C
        next_state_golden = (in == 0) ? 4'b1000 : 4'b0100;
        out_golden = 0;
      end
      4'b1000: begin // State D
        next_state_golden = (in == 0) ? 4'b0100 : 4'b0010;
        out_golden = 1;
      end
      default: begin
        next_state_golden = 4'b0000; // Invalid state
        out_golden = 0;
      end
    endcase

    // Check for errors
    if (next_state != next_state_golden || out != out_golden) begin
      error_count += 1;
      if (error_count == 1) begin
        error_time = $time;
        $display("Mismatch detected at time %t", $time);
        $display("First mismatch details:");
        $display("State: %b", state);
        $display("Input: %b", in);
        $display("Expected next_state: %b, got: %b", next_state_golden, next_state);
        $display("Expected out: %b, got: %b", out_golden, out);
      end
    end
  end

  // Simulation end and result display
  always @(negedge clk) begin
    if (error_count == 0) begin
      $display("SIMULATION PASSED");
    end else begin
      $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", error_count, error_time);
    end
  end
endmodule