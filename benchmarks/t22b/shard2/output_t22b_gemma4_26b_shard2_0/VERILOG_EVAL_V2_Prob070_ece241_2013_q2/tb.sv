`timescale 1 ps/1 ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic a, b, c, d,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable,
    input tb_match
);

    task wavedrom_start(input[511:0] title = "");
    endtask
    
    task wavedrom_stop;
        #1;
    endtask    

    bit fail = 0;
    bit fail1 = 0;
    always @(posedge clk, negedge clk)
        if (!tb_match)
            fail = 1;

    initial begin
        @(posedge clk) {a,b,c,d} <= 0;
        @(posedge clk) {a,b,c,d} <= 1;
        @(posedge clk) {a,b,c,d} <= 2;
        @(posedge clk) {a,b,c,d} <= 4;
        @(posedge clk) {a,b,c,d} <= 5;
        @(posedge clk) {a,b,c,d} <= 6;
        @(posedge clk) {a,b,c,d} <= 7;
        @(posedge clk) {a,b,c,d} <= 9;
        @(posedge clk) {a,b,c,d} <= 10;
        @(posedge clk) {a,b,c,d} <= 13;
        @(posedge clk) {a,b,c,d} <= 14;
        @(posedge clk) {a,b,c,d} <= 15;
        @(posedge clk) fail1 = fail;
        
        for (int i=0; i<16; i++) begin
            @(posedge clk) {a,b,c,d} <= i;
        end
        
        repeat(50) @(posedge clk, negedge clk) begin
            {a,b,c,d} <= $random;
        end
            
        if (fail && ~fail1)
            $display("Hint: Your circuit passes on the 12 required input combinations, but doesn't match the don't-care cases. Are you using minimal SOP and POS?");

        $finish;
    end
endmodule

module tb();

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out_sop;
        int errortime_out_sop;
        int errors_out_pos;
        int errortime_out_pos;
        int clocks;
    } stats;
    
    stats stats1;
    
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    int wavedrom_hide_after_time;
    
    reg clk=0;
    initial forever #5 clk = ~clk;

    logic a;
    logic b;
    logic c;
    logic d;
    logic out_sop_ref;
    logic out_sop_dut;
    logic out_pos_ref;
    logic out_pos_dut;

    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, a, b, c, d, out_sop_ref, out_sop_dut, out_pos_ref, out_pos_dut);
    end

    wire tb_match;
    wire tb_mismatch = ~tb_match;
    
    bit mismatch_displayed = 0;

    stimulus_gen stim1 (
        .clk,
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match),
        .a,
        .b,
        .c,
        .d
    );

    // RefModule is assumed to be provided by the environment as per golden TB
    RefModule good1 (
        .a,
        .b,
        .c,
        .d,
        .out_sop(out_sop_ref),
        .out_pos(out_pos_ref)
    );
        
    TopModule top_module1 (
        .a,
        .b,
        .c,
        .d,
        .out_sop(out_sop_dut),
        .out_pos(out_pos_dut)
    );

    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask    

    assign tb_match = ( { out_sop_ref, out_pos_ref } === ( { out_sop_ref, out_pos_ref } ^ { out_sop_dut, out_pos_dut } ^ { out_sop_ref, out_pos_ref } ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;

            // Combinational mismatch display requirement
            if (!mismatch_displayed) begin
                $display("First mismatch detected at time %t", $time);
                $display("Inputs: a=%b, b=%b, c=%b, d=%b (val=%d)", a, b, c, d, {a,b,c,d});
                $display("Got: out_sop=%b, out_pos=%b", out_sop_dut, out_pos_dut);
                $display("Exp: out_sop=%b, out_pos=%b", out_sop_ref, out_pos_ref);
                mismatch_displayed = 1;
            end
        end else begin
            mismatch_displayed = 0;
        end

        // SOP Error Tracking
        if (out_sop_ref !== ( out_sop_ref ^ out_sop_dut ^ out_sop_ref )) begin 
            if (stats1.errors_out_sop == 0) stats1.errortime_out_sop = $time;
            stats1.errors_out_sop = stats1.errors_out_sop + 1;
        end

        // POS Error Tracking
        if (out_pos_ref !== ( out_pos_ref ^ out_pos_dut ^ out_pos_ref )) begin 
            if (stats1.errors_out_pos == 0) stats1.errortime_out_pos = $time;
            stats1.errors_out_pos = stats1.errors_out_pos + 1;
        end
    end

    final begin
        if (stats1.errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
        end

        if (stats1.errors_out_sop) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_sop", stats1.errors_out_sop, stats1.errortime_out_sop);
        else $display("Hint: Output '%s' has no mismatches.", "out_sop");
        
        if (stats1.errors_out_pos) $display("Hint: Output '%s' has %0d mismatches. First mismatch occurred at time %0d.", "out_pos", stats1.errors_out_pos, stats1.errortime_out_pos);
        else $display("Hint: Output '%s' has no mismatches.", "out_pos");

        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %1d in %1d samples", stats1.errors, stats1.clocks);
    end

    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end

endmodule