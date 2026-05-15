`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module RefModule (
    input  logic a,
    input  logic b,
    input  logic sel_b1,
    input  logic sel_b2,
    output logic out_assign,
    output logic out_always
);
    assign out_assign = (sel_b1 && sel_b2) ? b : a;
    always_comb begin
        if (sel_b1 && sel_b2) out_always = b;
        else out_always = a;
    end
endmodule

module stimulus_gen (
    input clk,
    output logic a, b, sel_b1, sel_b2,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    task wavedrom_start(input [511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    initial begin
        {a, b, sel_b1, sel_b2} <= 4'b000;
        @(negedge clk) wavedrom_start("");
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0100;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1000;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1101;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0001;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0110;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1010;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1111;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0011;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0111;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1011;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b1111;
            @(posedge clk, negedge clk) {a,b,sel_b1,sel_b2} <= 4'b0011;
        wavedrom_stop();
        repeat(100) @(posedge clk, negedge clk)
            {a,b,sel_b1,sel_b2} <= $urandom;
        $finish;
    end
    
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_assign;
        int errortime_out_assign;
        int errors_out_always;
        int errortime_out_always;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic a;
    logic b;
    logic sel_b1;
    logic sel_b2;
    logic out_assign_ref;
    logic out_assign_dut;
    logic out_always_ref;
    logic out_always_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, sel_b1, sel_b2, out_assign_ref, out_assign_dut, out_always_ref, out_always_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    stimulus_gen stim1 (
        .clk(clk),
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );

    RefModule good1 (
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .out_assign(out_assign_ref),
        .out_always(out_always_ref)
    );
        
    TopModule top_module1 (
        .a(a),
        .b(b),
        .sel_b1(sel_b1),
        .sel_b2(sel_b2),
        .out_assign(out_assign_dut),
        .out_always(out_always_dut)
    );

    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { out_assign_ref, out_always_ref } === ( { out_assign_ref, out_always_ref } ^ { out_assign_dut, out_always_dut } ^ { out_assign_ref, out_always_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) begin
                stats1.errortime = $time;
                $display("FIRST MISMATCH DETECTED at %0t ps:", $time);
                $display("Inputs: a=%b, b=%b, sel_b1=%b, sel_b2=%b", a, b, sel_b1, sel_b2);
                $display("Expected: out_assign=%b, out_always=%b", out_assign_ref, out_always_ref);
                $display("Actual:   out_assign=%b, out_always=%b", out_assign_dut, out_always_dut);
            end
            stats1.errors++;
        end

        if (out_assign_ref !== ( out_assign_ref ^ out_assign_dut ^ out_assign_ref )) begin
            if (stats1.errors_out_assign == 0) stats1.errortime_out_assign = $time;
            stats1.errors_out_assign = stats1.errors_out_assign + 1;
        end

        if (out_always_ref !== ( out_always_ref ^ out_always_dut ^ out_always_ref )) begin
            if (stats1.errors_out_always == 0) stats1.errortime_out_always = $time;
            stats1.errors_out_always = stats1.errors_out_always + 1;
        end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_out_assign) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_assign", stats1.errors_out_assign, stats1.errortime_out_assign);
        else $display("Hint: Output '%s' has no mismatches.", "out_assign");

        if (stats1.errors_out_always) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_always", stats1.errors_out_always, stats1.errortime_out_always);
        else $display("Hint: Output '%s' has no mismatches.", "out_always");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
      #1000000
      $display("TIMEOUT");
      $finish();
    end

endmodule