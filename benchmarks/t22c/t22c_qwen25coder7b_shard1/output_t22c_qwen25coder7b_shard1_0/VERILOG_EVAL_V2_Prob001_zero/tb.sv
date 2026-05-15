`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13
topmodule_if u_if;

module tb();
typedef struct packed {
 int errors;
 int errortime;
 int errors_zero;
 int errortime_zero;
 int clocks;
} stats;

stats stats1;
wire[511:0] wavedrom_title;
wire wavedrom_enable;
wire tb_match;
wire tb_mismatch = ~tb_match;
reg clk=0;
initial forever #5 clk = ~clk;
logic zero_ref;
logic zero_dut;
stimulus_gen stim1 (.clk(u_if.clk), .wavedrom_title(u_if.wavedrom_title), .wavedrom_enable(u_if.wavedrom_enable));
RefModule good1 (.zero(zero_ref));
TopModule top_module1 (.zero(zero_dut));
bit strobe = 0;
task wait_for_end_of_timestep;
repeat(5) begin strobe <= !strobe; @(strobe); end
endtask
task wavedrom_start(input[511:0] title = "");
endtask

initial begin
 wavedrom_start("Output should 0");
 repeat(20) @(posedge u_if.clk, negedge u_if.clk);
 wavedrom_stop();

 #1 $finish;
end

final begin
 if (stats1.errors_zero)
 $display("Hint: Output 'zero' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_zero, stats1.errortime_zero);
 else
 $display("Hint: Output 'zero' has no mismatches.");
 $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
 $display("Simulation finished at %0d ps", $time);
 $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
end
assign tb_match = ( { zero_ref } === ( { zero_ref } ^ { zero_dut } ^ { zero_ref } ) );
always @(posedge u_if.clk, negedge u_if.clk) begin
 stats1.clocks++;
 if (!tb_match) begin
 if (stats1.errors == 0)
 stats1.errortime = $time;
 stats1.errors++;
 end
 if (zero_ref !== ( zero_ref ^ zero_dut ^ zero_ref )) begin
 if (stats1.errors_zero == 0)
 stats1.errortime_zero = $time;
 stats1.errors_zero = stats1.errors_zero + 1'b1;
 end
end
initial begin
 #1000000;
 $display("TIMEOUT");
 $finish();
end
endmodule
