module TopModule(
    input  logic a,
    input  logic b,
    output logic q
);

    // Combinational logic: output is 1 only when both inputs are 1
    assign q = a & b;

endmodule