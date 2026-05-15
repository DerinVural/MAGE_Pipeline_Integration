module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    output logic out
);

    // The K-map shows that out is 0 only when a=0, b=0, and c=0.
    // For all other combinations, out is 1.
    // This corresponds to the OR operation of a, b, and c.
    assign out = a | b | c;

endmodule