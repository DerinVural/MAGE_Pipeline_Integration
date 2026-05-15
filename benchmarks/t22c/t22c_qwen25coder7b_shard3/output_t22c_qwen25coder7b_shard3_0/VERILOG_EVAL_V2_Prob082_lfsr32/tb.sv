`timescale 1ps/1ps

`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input logic clk,
    output logic reset
);

logic clk_gen;
logic reset_gen;

initial begin
    clk_gen = 1'b0;
    reset_gen = 1'b0;

    repeat(400) @(posedge clk, negedge clk) begin
        clk_gen <= ~clk_gen;
        reset_gen <= ~($random & 31);
    end

    @(posedge clk)
    reset_gen <= 1'b0;

    repeat(200000)
    @(posedge clk);

    reset_gen <= 1'b1;

    repeat(5)
    @(posedge clk);

    #1 $finish;
end

endmodule

module tb();
typedef struct packed {
    int errors;
    int errortime;
    int errors_q;
    int errortime_q;
    int clocks;
} stats;

stats stats1;

wire [511:0] wavedrom_title;
wire wavedrom_enable;
int wavedrom_hide_after_time;

logic clk=0;
initial forever
    #5 clk = ~clk;

logic reset;
logic [31:0] q_ref;
logic [31:0] q_dut;

initial begin 
    $dumpfile("wave.vcd");
    $dumpvars(1, stim1.clk, tb_mismatch ,clk,reset,q_ref,q_dut );
end

wire tb_match; // Verification
wire tb_mismatch = ~tb_match;

stimulus_gen stim1 (
    .clk(clk),
    .reset(reset)
);
RefModule good1 (
    .clk(clk),
    .reset(reset),
    .q(q_ref) );

TopModule top_module1 (
    .clk(clk),
    .reset(reset),
    .q(q_dut) );

bit strobe = 0;
task wait_for_end_of_timestep;
    repeat(5) begin
        strobe <= !strobe; // Try to delay until the very end of the time step.
        @(strobe);
    end
endtask

final begin
    if (stats1.errors_q) begin
        $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
    end else begin
        $display("Hint: Output 'q' has no mismatches.");
    end

    $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
    $display("Simulation finished at %0d ps", $time);
    $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    if (stats1.errors == 0) begin
        $display("SIMULATION PASSED");
    end else begin
        $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
    end
end

// Verification: XORs on the right makes any X in good_vector match anything, but X in dut_vector will only match X.
assign tb_match = ( { q_ref } === ( { q_ref } ^ { q_dut } ^ { q_ref } ) );
// Use explicit sensitivity list here. @(*) causes NetProc::nex_input() to be called when trying to compute
// the sensitivity list of the @(strobe) process, which isn't implemented.
always @(posedge clk, negedge clk) begin
    stats1.clocks++;
    if (!tb_match) begin
        if (stats1.errors == 0) stats1.errortime = $time;
        stats1.errors++;
    end
    if (q_ref !== ( q_ref ^ q_dut ^ q_ref ))
    begin if (stats1.errors_q == 0) stats1.errortime_q = $time;
        stats1.errors_q = stats1.errors_q + 1'b1; end
end

/* Add timeout after 100K cycles */
initial begin
    #1000000;
    $display("TIMEOUT");
    $finish();
end

endmodule
