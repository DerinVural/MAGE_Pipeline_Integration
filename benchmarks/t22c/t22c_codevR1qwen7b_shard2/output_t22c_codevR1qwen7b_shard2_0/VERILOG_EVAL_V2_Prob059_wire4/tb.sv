`timescale 1ps/1ps
module stimulus_gen (input clk, output logic a, b, c, output [511:0] wavedrom_title, output logic wavedrom_enable);
reg [2:0] state_reg;
localparam STATE_A = 0, STATE_B = 1, STATE_C = 2, STATE_D = 3, STATE_E = 4;
initial state_reg = STATE_A;
always @(posedge clk) begin
 case (state_reg)
 STATE_A: begin state_reg <= STATE_B; {a,b,c} <= $random; wavedrom_enable <= 1; end
 STATE_B: begin state_reg <= STATE_C; {a,b,c} <= $random; end
 STATE_C: begin state_reg <= STATE_D; {a,b,c} <= $random; end
 STATE_D: begin state_reg <= STATE_E; {a,b,c} <= $random; end
 STATE_E: begin state_reg <= STATE_A; {a,b,c} <= $random; wavedrom_enable <= 0; end
 default: state_reg <= STATE_A;
 endcase
end
endmodule

module tb();
typedef struct {
 int errors; int errortime; int errors_w; int errortime_w; int errors_x; int errortime_x; int errors_y; int errortime_y; int errors_z; int errortime_z; int clocks;
} stats; stats stats1 = '0;
wire [511:0] wavedrom_title;
logic wavedrom_enable;
reg clk = 0; initial forever #5 clk = ~clk;
logic a, b, c;
logic w_ref, x_ref, y_ref, z_ref;
logic w_dut, x_dut, y_dut, z_dut;
wire tb_match = ({w_ref, x_ref, y_ref, z_ref} === ({w_ref, x_ref, y_ref, z_ref} ^ {w_dut, x_dut, y_dut, z_dut} ^ {w_ref, x_ref, y_ref, z_ref}});
stimulus_gen stim1(clk, a, b, c, wavedrom_title, wavedrom_enable);
RefModule good1(a, b, c, .w(w_ref), .x(x_ref), .y(y_ref), .z(z_ref));
TopModule top_module1(a, b, c, w_dut, x_dut, y_dut, z_dut);
bit strobe = 0; task wait_for_end; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
initial begin
 $dumpfile("wave.vcd"); $dumpvars(1, top_module1, a, b, c, w_dut, x_dut, y_dut, z_dut);
 @(negedge clk) begin
 wavedrom_enable = 0;
 repeat(8) @(posedge clk);
 @(negedge clk) $finish;
 end
 #1000000; $display("TIMEOUT"); $finish;
end
always @(posedge clk) begin
 stats1.clocks++;
 if (!tb_match) begin
 if (stats1.errors == 0) stats1.errortime = $time;
 stats1.errors++;
 if (w_ref !== (w_ref ^ w_dut ^ w_ref)) begin
 if (stats1.errors_w == 0) stats1.errortime_w = $time;
 stats1.errors_w++;
 end
 if (x_ref !== (x_ref ^ x_dut ^ x_ref)) begin
 if (stats1.errors_x == 0) stats1.errortime_x = $time;
 stats1.errors_x++;
 end
 if (y_ref !== (y_ref ^ y_dut ^ y_ref)) begin
 if (stats1.errors_y == 0) stats1.errortime_y = $time;
 stats1.errors_y++;
 end
 if (z_ref !== (z_ref ^ z_dut ^ z_ref)) begin
 if (stats1.errors_z == 0) stats1.errortime_z = $time;
 stats1.errors_z++;
 end
 end
end
final begin
 if (stats1.errors > 0)
 $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
 else
 $display("SIMULATION PASSED");
 $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
end
endmodule