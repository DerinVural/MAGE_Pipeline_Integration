`timescale 1ps/1ps
module tb();
  reg clk = 0;
  reg reset;
  reg ena;
  wire pm;
  wire [7:0] hh, mm, ss;
  always #5 clk = ~clk;

  localparam MAX_QUEUE_SIZE = 10;
  reg [2:0] input_queue [0:MAX_QUEUE_SIZE-1];
  reg [7:0] hh_queue [0:MAX_QUEUE_SIZE-1];
  reg [7:0] mm_queue [0:MAX_QUEUE_SIZE-1];
  reg [7:0] ss_queue [0:MAX_QUEUE_SIZE-1];
  reg pm_queue [0:MAX_QUEUE_SIZE-1];
  reg [31:0] time_queue [0:MAX_QUEUE_SIZE-1];
  integer queue_ptr = 0;
  integer errors_pm = 0, errors_hh = 0, errors_mm = 0, errors_ss = 0;
  integer err_time_pm = 0, err_time_hh = 0, err_time_mm = 0, err_time_ss = 0;
  integer total_errors = 0;

  TopModule dut (
    .clk(clk),
    .reset(reset),
    .ena(ena),
    .pm(pm),
    .hh(hh),
    .mm(mm),
    .ss(ss)
  );

  reg pm_ref;
  reg [7:0] hh_ref, mm_ref, ss_ref;

  always @(posedge clk) begin
    if (reset) begin
      pm_ref <= 0;
      hh_ref <= 8'h12;
      mm_ref <= 0;
      ss_ref <= 0;
    end else if (ena) begin
      if (ss_ref == 8'h59) begin
        ss_ref <= 0;
        if (mm_ref == 8'h59) begin
          mm_ref <= 0;
          if (hh_ref == 8'h12 && pm_ref) begin
            hh_ref <= 8'h12;
            pm_ref <= 0;
          end else if (hh_ref == 8'h11) begin
            hh_ref <= pm_ref ? 8'h12 : 8'h1;
            pm_ref <= ~pm_ref;
          end else if (hh_ref == 8'h00) begin
            hh_ref <= 8'h12;
            pm_ref <= 0;
          end else begin
            hh_ref <= hh_ref[0] ? 8'h1 : hh_ref + 1;
          end
        end else begin
          mm_ref <= mm_ref + 1;
        end
      end else begin
        ss_ref <= ss_ref + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (queue_ptr >= MAX_QUEUE_SIZE) begin
      queue_ptr <= 0;
    end
    input_queue[queue_ptr] = {reset, ena};
    hh_queue[queue_ptr] = hh;
    mm_queue[queue_ptr] = mm;
    ss_queue[queue_ptr] = ss;
    pm_queue[queue_ptr] = pm;
    time_queue[queue_ptr] = $time;
    queue_ptr <= queue_ptr + 1;

    if (pm !== pm_ref) begin
      if (errors_pm == 0) begin
        $display("%t : MISMATCH DETECTED AT TIME %0d: PM MISMATCH. EXPECTED %b, GOT %b. FIRST MISMATCH AT TIME %0d\n", $time, $time, pm_ref, pm, time_queue[0]);
        errors_pm = 1;
        err_time_pm = time_queue[0];
      end
      total_errors = total_errors + 1;
    end
    if (hh_queue[queue_ptr][3:0] >= 4'd10 || hh_queue[queue_ptr][7:4] >= 4'd10) begin
      if (errors_hh == 0) begin
        $display("%t : HH ERROR AT TIME %0d: %b\n", $time, $time, hh_queue[queue_ptr]);
        errors_hh = 1;
        err_time_hh = time_queue[0];
      end
      total_errors = total_errors + 1;
    end
    // Similar checks for mm and ss
  end

  initial begin
    repeat(100000) begin
      #100000;
      if (total_errors == 0) begin
        $display("SIMULATION PASSED\n");
      end else begin
        $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d\n", total_errors, err_time_pm);
      end
      $finish;
    end
  end
endmodule