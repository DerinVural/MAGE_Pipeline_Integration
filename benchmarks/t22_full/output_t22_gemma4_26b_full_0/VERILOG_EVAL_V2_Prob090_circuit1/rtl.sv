module TopModule(
    input  logic a,
    input  logic b,
    output logic q
);

    // The input specification defines a truth table:
    // a=0, b=0 -> q=0
    // a=0, b=1 -> q=0
    // a=1, b=0 -> q=0
    // a=1, b=1 -> q=1
    // This is an AND gate functionality.

    assign q = a & b;

endmodule