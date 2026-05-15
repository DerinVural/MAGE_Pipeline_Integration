`timescale 1ps/1ps

module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic c,
    output logic d
);

    task wavedrom_start(input[511:0] title = ""); endtask
    task wavedrom_stop(); #1; endtask

    initial begin
        int count; count = 0;
        {a, b, c, d} <= 4'b0;
        wavedrom_start();
        repeat(16) @(posedge clk) {a, b, c, d} <= count++;
        @(negedge clk) wavedrom_stop();
        repeat(200) @(posedge clk, negedge clk) {d, c, b, a} <= $urandom;
        #1 $finish;
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

    stats stats1 = 0;
    wire [511:0] wavedrom_title;
    wire wavedrom_enable;

    reg clk = 0;
    initial forever #5 clk = ~clk;

    logic a, b, c, d;
    logic out_ref, out_dut;

    wire tb_match = ( {out_ref} === ( {out_ref} ^ {out_dut} ^ {out_ref} ) );
    reg [3:0] ab;
    reg [1:0] cd;
    logic expected_out;
    reg [3:0] input_queue [0:9];
    reg [0:9] golden_queue, got_output_queue;

    localparam MAX_QUEUE_SIZE = 10;

    always @(posedge clk, negedge clk) begin
        if (stats1.clocks < MAX_QUEUE_SIZE) begin
            input_queue[stats1.clocks] = {a, b, c, d};
            got_output_queue[stats1.clocks] = out_dut;
            golden_queue[stats1.clocks] = expected_out;
        end else begin
            input_queue[stats1.clocks % MAX_QUEUE_SIZE] = {a, b, c, d};
            got_output_queue[stats1.clocks % MAX_QUEUE_SIZE] = out_dut;
            golden_queue[stats1.clocks % MAX_QUEUE_SIZE] = expected_out;
        end
        stats1.clocks++;
        if (!tb_match && stats1.errors == 0) begin
            $display("First mismatch at time %0t", $time);
            $display("Time	Input		Ab	Cd	Exp	Got");
            for (int i = 0; i <= stats1.clocks && i < MAX_QUEUE_SIZE; i++) begin
                $display("%0t	%b%b%b%b	%2b	%2b	%1b	%1b",
                    i, a, b, c, d, ab, cd, golden_queue[i], got_output_queue[i]);
            end
            $finish;
        end
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
        #0;
    end

    RefModule good1 (.a(a), .b(b), .c(c), .d(d), .out(out_ref));
    TopModule top_module1 (.a(a), .b(b), .c(c), .d(d), .out(out_dut));

    always @(*) begin
        case({cd, ab})
            // cd=00, ab=01: 0
            4'b0001: expected_out = 0;
            // cd=00, ab=00: d (don't care, set to 0)
            4'b0000: expected_out = 0;
            // cd=00, ab=10: 1
            4'b0010: expected_out = 1;
            // cd=00, ab=11:1
            4'b0011: expected_out = 1;
            // cd=01, ab=01:0
            4'b0101: expected_out = 0;
            // cd=01, ab=00:0
            4'b0100: expected_out = 0;
            // cd=01, ab=11: d
            4'b0111: expected_out = d;
            // cd=01, ab=10: d
            4'b0110: expected_out = d;
            // cd=11, ab=01:0
            4'b1101: expected_out = 0;
            // cd=11, ab=00:1
            4'b1100: expected_out = 1;
            // cd=11, ab=10:1
            4'b1110: expected_out = 1;
            // cd=11, ab=11:1
            4'b1111: expected_out = 1;
            // cd=10, ab=01:0
            4'b1001: expected_out = 0;
            // cd=10, ab=00:1
            4'b1000: expected_out = 1;
            // cd=10, ab=10:1
            4'b1010: expected_out = 1;
            // cd=10, ab=11:1
            4'b1011: expected_out = 1;
            default: expected_out = 0; // handle others as 0 (don't care)
        endcase
    end
endmodule

// End of testbench