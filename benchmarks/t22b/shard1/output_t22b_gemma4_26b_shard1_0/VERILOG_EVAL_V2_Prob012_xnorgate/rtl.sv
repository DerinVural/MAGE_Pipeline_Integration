module TopModule (
    input  logic a,
    input  logic b,
    output logic out
);

    // XNOR logic: out is 1 if a and b are equal, 0 otherwise.
    assign out = ~(a ^ b);

endmodule