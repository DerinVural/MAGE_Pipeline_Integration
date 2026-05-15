module TopModule (input logic clk, input logic reset, output logic [3:0] q);

    localparam COUNT_START = 4'd1;
    localparam COUNT_MAX = 4'd10;

    logic [3:0] next_q;

    // Sequential logic with synchronous reset
    always_ff @(posedge clk) begin
        if (reset)
            q <= COUNT_START;
        else
            q <= next_q;
    end

    // Combinational logic for next state
    always_comb begin
        if (q == COUNT_MAX)
            next_q = COUNT_START;
        else
            next_q = q + 4'd1;
    end

endmodule