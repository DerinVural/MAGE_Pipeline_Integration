`timescale 1ps/1ps
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
    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic [7:0] d;
    logic [7:0] q_ref;
    logic [7:0] q_dut;
    bit strobe = 0;

    task wait_for_end_of_timestep();
        repeat(5) begin
            strobe <= !strobe;
            @(strobe);
        end
    endtask

    RefModule good1 ( .clk(clk), .d(d), .q(q_ref) );
    TopModule top_module1 ( .clk(clk), .d(d), .q(q_dut) );

    wire tb_match = ( {q_ref} === ( {q_ref} ^ {q_dut} ^ {q_ref} ) );

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== ( q_ref ^ q_dut ^ q_ref )) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end

    initial begin
        #1000000;
        if (stats1.errors_q) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_q, stats1.errortime_q);
            $display("%0d'h%h %0d'h%h %0d'h%h", $time, clk, $time, d, $time, q_ref, $time, q_dut);
            if ($bits(clk) <= 64) $display("%0d'b%b", $time, clk);
            if ($bits(d) <= 64) $display("%0d'b%b", $time, d);
            if ($bits(q_ref) <= 64) $display("%0d'b%b", $time, q_ref);
            if ($bits(q_dut) <= 64) $display("%0d'b%b", $time, q_dut);
        end else begin
            $display("SIMULATION PASSED");
        end
        $finish();
    end
endmodule
