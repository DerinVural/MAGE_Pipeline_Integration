module tb();
    typedef packed struct {
        int errors;
        int errortime;
        int errors_p1y;
        int errortime_p1y;
        int errors_p2y;
        int errortime_p2y;
        int clocks;
    } stats;
    stats stats1 = '0;
    reg clk = 0;
    logic p1a, p1b, p1c, p1d;
    logic p2a, p2b, p2c, p2d;
    logic p1y_ref, p1y_dut, p2y_ref, p2y_dut;
    RefModule ref1(
        .p1a(p1a), .p1b(p1b), .p1c(p1c), .p1d(p1d),
        .p2a(p2a), .p2b(p2b), .p2c(p2c), .p2d(p2d),
        .p1y(p1y_ref), .p2y(p2y_ref)
    );
    TopModule top_module_inst (
        .p1a(p1a), .p1b(p1b), .p1c(p1c), .p1d(p1d),
        .p2a(p2a), .p2b(p2b), .p2c(p2c), .p2d(p2d),
        .p1y(p1y_dut), .p2y(p2y_dut)
    );
    initial forever #5 clk = ~clk;
    always @(posedge clk or negedge clk) begin
        stats1.clocks++;
        if ({p1y_ref, p2y_ref} !== {p1y_dut, p2y_dut}) begin
            stats1.errors++;
            if (stats1.errors == 1) stats1.errortime = $time;
            if (p1y_ref !== p1y_dut && stats1.errors_p1y == 0) begin
                stats1.errortime_p1y = $time;
                stats1.errors_p1y++;
            end
            if (p2y_ref !== p2y_dut && stats1.errors_p2y == 0) begin
                stats1.errortime_p2y = $time;
                stats1.errors_p2y++;
            end
        end
    end
    initial begin
        wait_for_stable();
        #1000000 $finish;
    end
    reg [3:0] count = 0;
    initial begin
        {p1a,p1b,p1c,p1d} = 0;
        {p2a,p2b,p2c,p2d} = 0;
        #10;
        repeat(20) @(posedge clk) begin
            {p1a,p1b,p1c,p1d} = count;
            {p2a,p2b,p2c,p2d} = count+1;
            count = count + 1;
        end
        repeat(200) @(posedge clk, negedge clk) begin
            {p1a,p1b,p1c,p1d,p2a,p2b,p2c,p2d} = $random;
        end
        #1 $finish;
    end
    final begin
        if (stats1.errors) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
            $display("First MISMATCH AT TIME %0d: Inputs: p1a=%b, p1b=%b, p1c=%b, p1d=%b, p2a=%b, p2b=%b, p2c=%b, p2d=%b", stats1.errortime, p1a, p1b, p1c, p1d, p2a, p2b, p2c, p2d);
            $display("Expected Outputs: p1y=%b, p2y=%b", p1y_ref, p2y_ref);
            $display("Actual Outputs: p1y=%b, p2y=%b", p1y_dut, p2y_dut);
        end else begin
            $display("SIMULATION PASSED");
        end
    end
    task wait_for_stable();
        bit strobe = 0;
        repeat(5) begin
            strobe <= ~strobe;
            @(strobe);
        end
    endtask
endmodule
module TopModule (logic p1a, logic p1b, logic p1c, logic p1d, logic p2a, logic p2b, logic p2c, logic p2d, logic p1y, logic p2y);
    assign p1y = ~(& {p1a, p1b, p1c, p1d});
    assign p2y = ~(& {p2a, p2b, p2c, p2d});
endmodule
module RefModule (logic p1a, p1b, p1c, p1d, logic p2a, p2b, p2c, p2d, logic p1y, logic p2y);
    assign p1y = ~(p1a & p1b & p1c & p1d);
    assign p2y = ~(p2a & p2b & p2c & p2d);
endmodule