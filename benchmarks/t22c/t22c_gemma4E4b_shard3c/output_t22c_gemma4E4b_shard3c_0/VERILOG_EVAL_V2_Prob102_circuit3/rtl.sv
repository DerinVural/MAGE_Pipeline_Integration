module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // Logic derived from waveform analysis: q = d AND (a OR b)
    assign q = d & (a | b);

endmodule