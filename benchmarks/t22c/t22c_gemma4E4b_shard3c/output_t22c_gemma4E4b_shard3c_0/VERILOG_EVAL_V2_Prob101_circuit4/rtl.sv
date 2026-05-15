module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // The circuit implements the logic derived from the simulation waveforms.
    // q is asserted (1) when the input combination is NOT one of the following states:
    // (0000), (0001), (1000), or (1001).
    assign q = ~(
        (a == 1'b0 && b == 1'b0 && c == 1'b0 && d == 1'b0) || 
        (a == 1'b0 && b == 1'b0 && c == 1'b0 && d == 1'b1) || 
        (a == 1'b1 && b == 1'b0 && c == 1'b0 && d == 1'b0) || 
        (a == 1'b1 && b == 1'b0 && c == 1'b0 && d == 1'b1)
    );

endmodule