module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // The function derived from the waveform is q = b | c
    assign q = b | c;

endmodule