module tb();

typedef struct packed {
    int errors;
    int errortime;
    int errors_pos;
    int errortime_pos;

    int clocks;
} stats;

stats stats1;

wire[511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

reg clk=0;
initial forever
    #5 clk = ~clk;

logic [7:0] in;
logic [2:0] pos;

initial begin 
    $dumpfile("wave.vcd");
    $dumpvars(1,stim1.clk,tb_mismatch,in,pos);
end

wire tb_match;        // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
    .clk(clk),
    .in(in),
    .wavedrom_title(wavedrom_title),
    .wavedrom_enable(wavedrom_enable)
);
RefModule good1 (
    .in(in),
    .pos(pos)
);

TopModule top_module1 (
    .in(in),
    .pos(pos)
);

bit strobe = 0;
task wait_for_end_of_timestep;
    repeat(5) begin
        strobe <= !strobe;  // Try to delay until the very end of the time step.
        @(strobe);
    end
endtask	

final begin
    if (stats1.errors_pos) $display("Hint: Output 'pos' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_pos, stats1.errortime_pos);
    else $display("Hint: Output 'pos' has no mismatches.");
    $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
    $display("Simulation finished at %0d ps", $time);
    if (stats1.errors == 0 && stats1.errors_pos == 0) $display("SIMULATION PASSED");
    else $display("SIMULATION FAILED - %d MISMATCHES DETECTED, FIRST AT TIME %d", stats1.errors + stats1.errors_pos, stats1.errortime_pos);
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { pos } === ( { pos } ^ { pos } ^ { pos } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin

    stats1.clocks++;
    if (!tb_match) begin
        if (stats1.errors == 0) stats1.errortime = $time;
        stats1.errors++;
    end
    if (pos !== ( pos ^ pos ^ pos ))
    begin if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
        stats1.errors_pos = stats1.errors_pos+1'b1; end

end		

// add timeout after 100K cycles
initial begin
  #1000000
  $display("TIMEOUT");
  $finish();
end

endmodule