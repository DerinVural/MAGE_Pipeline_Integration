module TopModule(
    input  logic in1,
    input  logic in2,
    output logic out
);

    // A NOR gate outputs 1 only if both inputs are 0.
    // This is equivalent to ~(in1 | in2).
    assign out = ~(in1 | in2);

endmodule