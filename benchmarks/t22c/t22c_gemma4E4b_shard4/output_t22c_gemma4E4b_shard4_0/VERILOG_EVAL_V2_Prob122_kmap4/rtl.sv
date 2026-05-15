module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // Implementation using a direct combinational assignment based on the K-map truth table.
    // This is the most direct form for combinational logic and avoids complex case statement overhead.
    assign out = (
        // Row 00 (a=0, b=0)
        (~a & ~b & ~c & d) |  // I=1 -> 1
        (~a & ~b & c & ~d) | // I=2 -> 1
        (~a & ~b & ~c & ~d) & 1'b0 | // I=0 -> 0 (Redundant, kept for clarity if needed, but simplified)
        (~a & ~b & c & d) & 1'b0 | // I=3 -> 0

        // Row 01 (a=0, b=1)
        (~a & b & ~c & ~d) | // I=4 -> 1
        (~a & b & ~c & d) & 1'b0 | // I=5 -> 0
        (~a & b & c & ~d) & 1'b0 | // I=6 -> 0
        (~a & b & c & d) | // I=7 -> 1

        // Row 10 (a=1, b=0)
        (a & ~b & ~c & ~d) | // I=8 -> 1
        (a & ~b & ~c & d) & 1'b0 | // I=9 -> 0
        (a & ~b & c & ~d) & 1'b0 | // I=10 -> 0
        (a & ~b & c & d) | // I=11 -> 1

        // Row 11 (a=1, b=1)
        (a & b & ~c & ~d) & 1'b0 | // I=12 -> 0
        (a & b & ~c & d) | // I=13 -> 1
        (a & b & c & ~d) | // I=14 -> 1
        (a & b & c & d) & 1'b0   // I=15 -> 0
    );

endmodule