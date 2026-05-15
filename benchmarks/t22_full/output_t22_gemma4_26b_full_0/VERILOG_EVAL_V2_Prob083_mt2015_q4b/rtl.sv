module TopModule(
    input  logic x,
    input  logic y,
    output logic z
);

    // The truth table derived from the waveform is:
    // x y | z
    // 0 0 | 1
    // 0 1 | 0
    // 1 0 | 0
    // 1 1 | 1
    // This is an XNOR gate.

    assign z = ~(x ^ y);

endmodule