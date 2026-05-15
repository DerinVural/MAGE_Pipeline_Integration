module TopModule(
    input  logic a,
    input  logic b,
    output logic out
);

    // A NOR gate outputs 1 only when both inputs are 0.
    // out = !(a | b)
    assign out = ~(a | b);

endmodule