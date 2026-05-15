module TopModule (
    input  logic clk,
    input  logic in,
    output logic out
);

    // Initialize the flip-flop output to 0 to avoid starting in an unknown state (X)
    initial begin
        out = 1'b0;
    end

    // The D flip-flop captures the XOR of 'in' and the current 'out'
    always @(posedge clk) begin
        out <= in ^ out;
    end

endmodule