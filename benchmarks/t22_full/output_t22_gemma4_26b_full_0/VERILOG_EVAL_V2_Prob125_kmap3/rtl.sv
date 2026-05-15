module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // Combinational logic implementation based on the Karnaugh Map
    // Simplified expression: out = (c & (a | ~b)) | (a & ~c)
    // This covers the 1s and makes optimal use of don't-cares.

    always @(*) begin
        out = (c & (a | ~b)) | (a & ~c);
    end

endmodule