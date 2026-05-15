module TopModule (
    input clk,
    input in,
    output logic out
);

    // Combinational logic to compute D input for the flip-flop
    logic d;
    always @(*) begin
        d = in ^ out;  // XOR of in and out
    end

    // Sequential logic for the positive edge-triggered D flip-flop
    always @(posedge clk) begin
        out <= d;
    end

endmodule