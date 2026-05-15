module stimulus_gen (
    input clk,
    output reg [7:0] d,
    output areset,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;

    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask

    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin srfail = !tb_match; reset <= 0; end
        if (srfail) $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask

    initial begin
        reset <= 1;
        d <= $random;
        @(negedge clk);
        @(negedge clk);
        wavedrom_start("Asynchronous active-high reset");
        reset_test(1);
        repeat(7) @(negedge clk) d <= $random;
        @(posedge clk) reset <= 1;
        @(negedge clk) reset <= 0; d <= $random;
        repeat(2) @(negedge clk) d <= $random;
        wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk) begin
            reset <= !($random & 15);
            d <= $random;
        end
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
    reg clk=0;
    initial forever #5 clk=~clk;

    logic [7:0] d;
    logic areset;
    logic [7:0] q_ref;
    logic [7:0] q_dut;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, stim1.clk, tb_mismatch, clk, d, areset, q_ref, q_dut);
    end

    wire tb_match = ~tb_mismatch;
    wire tb_mismatch = ({q_ref} === ({q_ref} ^ {q_dut} ^ {q_ref}));

    bit strobe=0;
    task wait_for_end_of_timestep;
        repeat(5) begin strobe <= !strobe; @(strobe); end
    endtask

    always @(posedge clk, negedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (q_ref !== (q_ref ^ q_dut ^ q_ref)) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
    end

    initial begin
        reset <= 1;
        d <= $random;
        @(negedge clk);
        @(negedge clk);
        wavedrom_start();
        reset_test(1);
        repeat(7) @(negedge clk) d <= $random;
        @(posedge clk) reset <=1;
        @(negedge clk) reset <=0; d <= $random;
        repeat(2) @(negedge clk) d <= $random;
        wavedrom_stop();
        repeat(400) @(posedge clk, negedge clk) begin
            reset <=!($random&15);
            d <= $random;
        end
        #1 $finish();
    end

    stimulus_gen stim1 (
        .clk(clk),
        .d(d),
        .areset(areset),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable)
    );
    RefModule good1 (
        .clk(clk),
        .d(d),
        .areset(areset),
        .q(q_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .areset(areset),
        .d(d),
        .q(q_dut)
    );

    final begin
        if (stats1.errors_q) begin
            $display("Hint: Output 'q' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_q, stats1.errortime_q);
        end else begin
            $display("SIMULATION PASSED");
        end
        $display("Simulation finished at %0d ps", $time);
        $display("Mismatches: %0d in %0d samples", stats1.errors, stats1.clocks);
    end

    initial #1e6 $display("TIMEOUT"); $finish();
endmodule