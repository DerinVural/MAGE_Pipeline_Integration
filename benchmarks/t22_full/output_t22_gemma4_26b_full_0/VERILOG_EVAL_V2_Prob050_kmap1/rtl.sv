module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    output logic out
);

    // The K-map shows that the output is 0 only when a=0, b=0, and c=0.
    // For all other combinations, the output is 1.
    // This corresponds to the logical OR operation: out = a | b | c;

    assign out = a | b | c;

endmodule