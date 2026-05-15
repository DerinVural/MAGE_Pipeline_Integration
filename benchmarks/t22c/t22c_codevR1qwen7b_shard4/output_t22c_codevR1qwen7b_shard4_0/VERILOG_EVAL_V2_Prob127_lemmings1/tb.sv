// Testbench code follows the golden testbench structure with proper hierarchy and signal connections.
`timescale 1ps/1ps
module tb();
    typedef struct packed {
        int errors;
        int errortime;
        int errors_walk_left;
        int errortime_walk_left;
        int errors_walk_right;
        int errortime_walk_right;
        int clocks;
    } stats;
    stats stats1;
    wire[511:0] wavedrom_title;
    wire wavedrom_enable;
    reg clk = 0;
    initial forever #5 clk = ~clk;
    logic areset;
    logic bump_left;
    logic bump_right;
    logic walk_left_ref;
    logic walk_right_ref;
    logic walk_left_dut;
    logic walk_right_dut;
    wire tb_match = ~((walk_left_ref !== walk_left_dut) || (walk_right_ref !== walk_right_dut));
    wire tb_mismatch = ~tb_match;
    stimulus_gen stim1 (
        .clk(clk),
        .areset(areset),
        .bump_left(bump_left),
        .bump_right(bump_right),
        .wavedrom_title(wavedrom_title),
        .wavedrom_enable(wavedrom_enable),
        .tb_match(tb_match)
    );
    RefModule ref_mod (
        .clk(clk),
        .areset(areset),
        .bump_left(bump_left),
        .bump_right(bump_right),
        .walk_left(walk_left_ref),
        .walk_right(walk_right_ref)
    );
    TopModule top_module1 (
        .clk(clk),
        .areset(areset),
        .bump_left(bump_left),
        .bump_right(bump_right),
        .walk_left(walk_left_dut),
        .walk_right(walk_right_dut)
    );
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(1, clk, areset, bump_left, bump_right, walk_left_ref, walk_left_dut, walk_right_ref, walk_right_dut);
    end
    reg first_mismatch = 1;
    reg [31:0] error_count = 0;
    reg [31:0] first_time;
    reg [31:0] walk_left_err_time, walk_right_err_time;
    always @(posedge clk) begin
        stats1.clocks++;
        if (tb_mismatch) begin
            if (error_count == 0) first_time = $time;
            error_count++;
            if (walk_left_ref !== walk_left_dut ^ walk_right_ref !== walk_right_dut) begin
                if (walk_left_ref !== walk_left_dut) begin
                    stats1.errors_walk_left++;
                    walk_left_err_time = $time;
                end else begin
                    stats1.errors_walk_right++;
                    walk_right_err_time = $time;
                end
            end
        end
        if (first_mismatch && tb_mismatch) begin
            first_mismatch = 0;
            $display("First Mismatch at time %0d:\n", $time);
            $display("Input Signals: bump_left=%b, bump_right=%b, areset=%b", bump_left, bump_right, areset);
            $display("Output Signals: walk_left_dut=%b, walk_right_dut=%b", walk_left_dut, walk_right_dut);
            $display("Expected Outputs: walk_left_ref=%b, walk_right_ref=%b", walk_left_ref, walk_right_ref);
            if (walk_left_ref !== walk_left_dut) $display("walk_left Mismatch at %0d", $time);
            else $display("walk_right Mismatch at %0d", $time);
        end
    end
    final begin
        if (error_count > 0) begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", error_count, first_time);
            $display("walk_left first mismatch at %0d: dut=%b, ref=%b", walk_left_err_time, walk_left_dut, walk_left_ref);
            $display("walk_right first mismatch at %0d: dut=%b, ref=%b", walk_right_err_time, walk_right_dut, walk_right_ref);
        end else $display("SIMULATION PASSED");
        $display("Total Mismatches: %0d out of %0d samples", error_count, stats1.clocks);
    end
    initial begin #1000000 $display("TIMEOUT"); $finish; end
endmodule

module stimulus_gen (
    input clk,
    output logic areset,
    output logic bump_left,
    output logic bump_right,
    output reg[511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    reg reset;
    assign areset = reset;
    task reset_test(input async=0);
        bit arfail, srfail, datafail;
        @(posedge clk);
        @(posedge clk) reset <= 0;
        repeat(3) @(posedge clk);
        @(negedge clk) begin datafail = !tb_match; reset <= 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            reset <= 0;
        end
        if (srfail) $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask
    task wavedrom_start(input[511:0] title = "/"); endtask
    task wavedrom_stop; #1; endtask
    initial begin
        reset <= 1;
        {bump_right, bump_left} <= 3'h3;
        wavedrom_start("Asynchronous reset");
        reset_test(1);
        repeat(3) @(posedge clk);
        {bump_right, bump_left} <= 2;
        repeat(2) @(posedge clk);
        {bump_right, bump_left} <= 1;
        repeat(2) @(posedge clk);
        wavedrom_stop();
        @(posedge clk);
        repeat(200) @(posedge clk, negedge clk) begin
            {bump_right, bump_left} <= $random & $random;
            reset <= !($random & 31);
        end
        #1 $finish;
    end
endmodule

module RefModule (
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    output logic walk_left,
    output logic walk_right
);
    localparam STATE_LEFT = 0, STATE_RIGHT = 1;
    logic state;
    always_ff @(posedge clk or posedge areset) begin
        if (areset) state <= STATE_LEFT;
        else state <= next_state;
    end
    logic next_state;
    always_comb begin
        case (state)
            STATE_LEFT: next_state = (bump_left || bump_right) ? STATE_RIGHT : STATE_LEFT;
            STATE_RIGHT: next_state = (bump_left || bump_right) ? STATE_LEFT : STATE_RIGHT;
            default: next_state = STATE_LEFT;
        endcase
    end
    assign walk_left = (state == STATE_LEFT);
    assign walk_right = (state == STATE_RIGHT);
endmodule

module TopModule (
    input logic clk,
    input logic areset,
    input logic bump_left,
    input logic bump_right,
    output logic walk_left,
    output logic walk_right
);
    localparam STATE_LEFT = 1'b0;
    localparam STATE_RIGHT = 1'b1;
    logic state;
    logic next_state;
    initial state = STATE_LEFT;
    always @(posedge clk or posedge areset) begin
        if (areset) state <= STATE_LEFT;
        else state <= next_state;
    end
    always @(*) begin
        case (state)
            STATE_LEFT: next_state = (bump_left || bump_right) ? STATE_RIGHT : STATE_LEFT;
            STATE_RIGHT: next_state = (bump_left || bump_right) ? STATE_LEFT : STATE_RIGHT;
            default: next_state = STATE_LEFT;
        endcase
    end
    assign walk_left = (state == STATE_LEFT);
    assign walk_right = (state == STATE_RIGHT);
endmodule