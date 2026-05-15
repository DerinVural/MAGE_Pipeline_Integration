module tb();
typedef struct packed {
    int errors;
    int errortime;
    int errors_predict_taken;
    int errortime_predict_taken;
    int errors_predict_history;
    int errortime_predict_history;
    int clocks;
} stats;
stats stats1;
wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;
reg clk=0;
initial forever #5 clk = ~clk;
logic areset;
logic predict_valid;
logic [6:0] predict_pc;
logic train_valid;
logic train_taken;
logic train_mispredicted;
logic [6:0] train_history;
logic [6:0] train_pc;
logic predict_taken_ref;
logic predict_taken_dut;
logic [6:0] predict_history_ref;
logic [6:0] predict_history_dut;
initial begin 
    $dumpfile("wave.vcd");
    $dumpvars(1, stim1.clk, tb_mismatch ,clk,areset,predict_valid,predict_pc,train_valid,train_taken,train_mispredicted,train_history,train_pc,predict_taken_ref,predict_taken_dut,predict_history_ref,predict_history_dut );
end
wire tb_match;      // Verification
wire tb_mismatch = ~tb_match;
stimulus_gen stim1 (
    .clk(clk),
    .areset(areset),
    .predict_valid(predict_valid),
    .predict_pc(predict_pc),
    .train_valid(train_valid),
    .train_taken(train_taken),
    .train_mispredicted(train_mispredicted),
    .train_history(train_history),
    .train_pc(train_pc),
    .tb_match(tb_match),
    .wavedrom_title(wavedrom_title),
    .wavedrom_enable(wavedrom_enable),
    .wavedrom_hide_after_time(wavedrom_hide_after_time)
);
RefModule good1 (
    .clk(clk),
    .areset(areset),
    .predict_valid(predict_valid),
    .predict_pc(predict_pc),
    .train_valid(train_valid),
    .train_taken(train_taken),
    .train_mispredicted(train_mispredicted),
    .train_history(train_history),
    .train_pc(train_pc),
    .predict_taken(predict_taken_ref),
    .predict_history(predict_history_ref) );
TopModule top_module1 (
    .clk(clk),
    .areset(areset),
    .predict_valid(predict_valid),
    .predict_pc(predict_pc),
    .train_valid(train_valid),
    .train_taken(train_taken),
    .train_mispredicted(train_mispredicted),
    .train_history(train_history),
    .train_pc(train_pc),
    .predict_taken(predict_taken_dut),
    .predict_history(predict_history_dut) );
bit strobe = 0;
task wait_for_end_of_timestep;
    repeat(5) begin
        strobe <= !strobe;  // Try to delay until the very end of the time step.
        @(strobe);
    end
endtask
final begin
    if (stats1.errors_predict_taken) $display("Hint: Output 'predict_taken' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_predict_taken, stats1.errortime_predict_taken);
    else $display("Hint: Output 'predict_taken' has no mismatches.");
    if (stats1.errors_predict_history) $display("Hint: Output 'predict_history' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_predict_history, stats1.errortime_predict_history);
    else $display("Hint: Output 'predict_history' has no mismatches.");
    $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    if (stats1.errors == 0) begin
        $display("SIMULATION PASSED");
    end else begin
        $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors, stats1.errortime);
    end
end
add timeout after 100K cycles
initial begin
  #1000000
  $display("TIMEOUT");
  $finish();
end
endmodule
