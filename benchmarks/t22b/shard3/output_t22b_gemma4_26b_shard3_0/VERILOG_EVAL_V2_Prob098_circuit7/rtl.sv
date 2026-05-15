module TopModule (
    input  logic clk,
    input  logic a,
    output logic q
);

    // Initialize output to a known value to avoid X
    initial begin
        q = 1'b0;
    end

    // Sequential logic: q follows the inverse of input a
    always @(posedge clk) begin
        q <= ~a;
    end

endmodule