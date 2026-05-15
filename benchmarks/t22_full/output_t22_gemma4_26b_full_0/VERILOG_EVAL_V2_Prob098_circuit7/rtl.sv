module TopModule(
    input  logic clk,
    input  logic a,
    output logic q
);

    // The waveform indicates that q is the delayed inverse of a.
    // q(t+1) = ~a(t)

    initial begin
        q = 1'b0;
    end

    always @(posedge clk) begin
        q <= ~a;
    end

endmodule