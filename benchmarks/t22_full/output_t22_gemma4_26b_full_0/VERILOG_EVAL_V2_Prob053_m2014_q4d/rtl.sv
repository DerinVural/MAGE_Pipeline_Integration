module TopModule(
    input  logic clk,
    input  logic in,
    output logic out
);

    // Initialize the output to a known value since there is no reset
    initial begin
        out = 1'b0;
    end

    // D flip-flop implementation
    // The input to the DFF is (in XOR out)
    always @(posedge clk) begin
        out <= in ^ out;
    end

endmodule