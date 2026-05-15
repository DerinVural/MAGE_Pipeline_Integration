module TopModule (
    input logic a,
    input logic b,
    output logic q
);

    // The waveform analysis shows q is high (1) only when both inputs a and b are high (1).
    // This corresponds to a logical AND operation: q = a & b.
    assign q = a & b;

endmodule