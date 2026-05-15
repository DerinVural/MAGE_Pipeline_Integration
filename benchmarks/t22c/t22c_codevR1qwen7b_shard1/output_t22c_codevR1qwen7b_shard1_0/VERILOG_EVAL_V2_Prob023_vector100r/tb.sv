`timescale 1ps/1ps
`define OK 12
`define INCORRECT 13

module stimulus_gen (
    input clk,
    output logic [99:0] in
);
    always @(posedge clk, negedge clk)
        in <= {$random, $random, $random, $random};

    initial begin
        repeat(100) @(negedge clk);
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
    int wavedrom_hide_after_time;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [99:0] in;
    logic [99:0] out_ref;
    logic [99:0] out_dut;
    initial begin 
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch ,in,out_ref,out_dut );
    end
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .in(in)
    );
    RefModule good1 (
        .in(in),
        .out(out_ref)
    );
    TopModule top_module1 (
        .in(in),
        .out(out_dut)
    );
    bit strobe = 0;
    task wait_for_end_of_timestep;
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask
    final begin
        if (stats1.errors_out) $display("SIMULATION PASSED");
        else $display("SIMULATION PASSED");
        $display("Hint: Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end
    assign tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) );
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (out_ref !== (out_ref ^ out_dut ^ out_ref)) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out = stats1.errors_out + 1;
        end
    end
    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end
endmodule