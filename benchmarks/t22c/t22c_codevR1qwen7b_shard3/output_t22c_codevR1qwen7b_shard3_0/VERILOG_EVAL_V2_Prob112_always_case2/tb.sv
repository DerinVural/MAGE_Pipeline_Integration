module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_pos;
        int errortime_pos;
        int clocks;
    } stats;
    stats stats1;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic [3:0] in;
    logic [1:0] pos_ref, pos_dut;
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, in, pos_ref, pos_dut);
    end
    wire tb_match;
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .in(in),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (.in(in), .pos(pos_ref));
    TopModule top_module1 (.in(in), .pos(pos_dut));
    bit strobe = 0;
    task wait_for_end_of_timestep(); repeat(5) begin strobe <= !strobe; @(strobe); end endtask
    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (pos_ref !== (pos_ref ^ pos_dut ^ pos_ref)) begin
            if (stats1.errors_pos == 0) stats1.errortime_pos = $time;
            stats1.errors_pos++;
        end
    end
    initial begin
        #1000000;
        $display("TIMEOUT");
        $finish();
    end
    final begin
        if (stats1.errors_pos) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors_pos, stats1.errortime_pos);
            $display("Input: in=%h%b", in, in);
            $display("Output pos_dut: %h%b", pos_dut, pos_dut);
            $display("Expected pos_ref: %h%b", pos_ref, pos_ref);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
endmodule