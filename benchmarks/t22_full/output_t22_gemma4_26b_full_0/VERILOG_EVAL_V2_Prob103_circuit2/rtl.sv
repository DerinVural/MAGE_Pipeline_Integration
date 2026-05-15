module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // The waveform represents an even parity generator.
    // q is 1 when the number of 1s in {a, b, c, d} is even (0, 2, or 4).
    // This is equivalent to ~(a ^ b ^ c ^ d).

    assign q = ~(a ^ b ^ c ^ d);

endmodule