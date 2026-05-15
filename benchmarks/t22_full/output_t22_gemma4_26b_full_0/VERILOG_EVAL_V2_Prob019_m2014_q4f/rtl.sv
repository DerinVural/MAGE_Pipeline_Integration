module TopModule(
    input  logic in1,
    input  logic in2,
    output logic out
);

    // The specification describes an AND gate where in2 has a bubble (inversion).
    // This is equivalent to: out = in1 AND (NOT in2)
    assign out = in1 & (~in2);

endmodule