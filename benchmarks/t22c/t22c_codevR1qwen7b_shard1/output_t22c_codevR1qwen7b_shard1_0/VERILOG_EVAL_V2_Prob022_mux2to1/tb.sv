module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic sel,
    output [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    task wavedrom_start(input [511:0] title = "Sel chooses between a and b"); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        {a, b, sel} <= 3'b000;
        @(negedge clk) wavedrom_start("Sel chooses between a and b");
        @(posedge clk) {a, b, sel} <= 3'b000;
        @(posedge clk) {a, b, sel} <= 3'b100;
        @(posedge clk) {a, b, sel} <= 3'b110;
        @(posedge clk) {a, b, sel} <= 3'b111;
        @(posedge clk) {a, b, sel} <= 3'b011;
        @(posedge clk) {a, b, sel} <= 3'b001;
        @(posedge clk) {a, b, sel} <= 3'b100;
        @(posedge clk) {a, b, sel} <= 3'b101;
        @(posedge clk) {a, b, sel} <= 3'b110;
        @(posedge clk) {a, b, sel} <= 3'b111;
        @(negedge clk) wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk) {a, b, sel} <= $random;
        $finish;
    end
endmodule

module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic a;
    logic b;
    logic sel;
    logic out_ref;
    logic out_dut;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, sel, out_ref, out_dut);
    end
    wire tb_match, tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .sel(sel),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out_ref)
    );
    TopModule top_module1 (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask
    final begin
        if (stats1.errors_out) $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_out, stats1.errortime_out);
        else $display("SIMULATION PASSED");
        $display("Hint: Output 'out' has %0d mismatches. First mismatch occurred at time %0d", stats1.errors_out, stats1.errortime_out);
        $display("Hint: Total mismatched samples is %0d out of %0d samples", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end
    assign tb_match = ({out_ref} === ({out_ref} ^ {out_dut} ^ {out_ref}));
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end
    initial #1000000 $display("TIMEOUT"); $finish();
endmodule