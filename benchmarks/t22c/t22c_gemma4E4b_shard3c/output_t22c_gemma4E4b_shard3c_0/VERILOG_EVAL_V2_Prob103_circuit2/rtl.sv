module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // The function derived from the input/output waveform trace.
    // Q is high for minterms: 0, 3, 5, 6, 9, 10, 12, 15.

    assign q = (
        (~a & ~b & ~c & ~d) | // 0000 -> 1
        (~a & ~b & c & d)  | // 0011 -> 1
        (~a & b & ~c & d)  | // 0101 -> 1
        (~a & b & c & ~d)  | // 0110 -> 1
        (a & ~b & ~c & d)  | // 1001 -> 1
        (a & ~b & c & ~d)  | // 1010 -> 1
        (a & b & ~c & ~d)  | // 1100 -> 1
        (a & b & c & d)    // 1111 -> 1
    );

endmodule