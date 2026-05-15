`timescale 1ps/1ps
module tb();
    logic clk = 0;
    initial forever #5 clk = ~clk;

    reg [7:0] in;
    logic [31:0] out_dut;
    wire tb_match;
    wire [31:0] out_ref = {{24{in[7]}}, in}; // Manual sign extension

    // Queue variables
    reg [7:0] input_queue [0:4]; // MAX_QUEUE_SIZE=5
    reg [31:0] expected_queue [0:4];
    reg [31:0] got_queue [0:4];
    integer queue_ptr = 0;

    // Error counting
    integer errors = 0;
    integer errortime = 0;

    // Mismatch detection
    assign tb_match = (out_dut === out_ref);

    // Clock-driven checks
    always @(posedge clk) begin
        if (queue_ptr >= 5) begin
            queue_ptr = 0;
        end
        input_queue[queue_ptr] = in;
        expected_queue[queue_ptr] = out_ref;
        got_queue[queue_ptr] = out_dut;
        queue_ptr++;

        if (!tb_match && errors == 0) begin
            errortime = $time;
        end
        if (!tb_match) begin
            errors++;
        end
    end

    // DUT Instantiation
    TopModule top_module1 (
        .in(in),
        .out(out_dut)
    );

    // Stimulus
    initial begin
        repeat(100) @(posedge clk);
        $finish;
    end

    // Simulation end and display
    initial begin
        wait(100);
        if (errors == 0) begin
            $display("SIMULATION PASSED");
        end else begin
            $display("SIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", errors, errortime);
        end
    end
endmodule