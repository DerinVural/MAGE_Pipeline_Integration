module tb();
typedef struct packed { int errors; int errortime; int errors_cout; int errortime_cout; int errors_sum; int errortime_sum; int clocks; } stats;
stats stats1 = 0;
logic [511:0] wavedrom_title;
logic wavedrom_enable;
int wavedrom_hide_after_time;
reg clk = 0;
initial forever #5 clk = ~clk;
logic a, b, cin;
logic cout_ref, cout_dut, sum_ref, sum_dut;
logic tb_match, tb_mismatch;
stimulus_gen stim1(.clk(clk), .a(a), .b(b), .cin(cin));
RefModule good1(.a(a), .b(b), .cin(cin), .cout(cout_ref), .sum(sum_ref));
TopModule top_module1(.a(a), .b(b), .cin(cin), .cout(cout_dut), .sum(sum_dut));
initial begin $dumpfile("wave.vcd"); $dumpvars(1, tb, clk, a, b, cin, cout_ref, cout_dut, sum_ref, sum_dut); end
bit strobe = 0;
task wait_for_end_of_timestep; repeat(5) begin strobe <= !strobe; @(strobe); end endtask
assign tb_match = ({cout_ref, sum_ref} === ({cout_ref, sum_ref} ^ {cout_dut, sum_dut} ^ {cout_ref, sum_ref}));
always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
        if (stats1.errors == 0) stats1.errortime = $time;
        stats1.errors++;
    end
    if (cout_ref !== (cout_ref ^ cout_dut ^ cout_ref)) begin
        if (stats1.errors_cout == 0) stats1.errortime_cout = $time;
        stats1.errors_cout++;
    end
    if (sum_ref !== (sum_ref ^ sum_dut ^ sum_ref)) begin
        if (stats1.errors_sum == 0) stats1.errortime_sum = $time;
        stats1.errors_sum++;
    end
end
initial begin #1000000 $display("TIMEOUT"); $finish(); end
final begin
    if (stats1.errors_cout) $display("Hint: Output 'cout' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_cout, stats1.errortime_cout);
    else $display("Hint: Output 'cout' has no mismatches.");
    if (stats1.errors_sum) $display("Hint: Output 'sum' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_sum, stats1.errortime_sum);
    else $display("Hint: Output 'sum' has no mismatches.");
    $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    if (stats1.errors > 0) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
    else $display("SIMULATION PASSED");
end
endmodule
