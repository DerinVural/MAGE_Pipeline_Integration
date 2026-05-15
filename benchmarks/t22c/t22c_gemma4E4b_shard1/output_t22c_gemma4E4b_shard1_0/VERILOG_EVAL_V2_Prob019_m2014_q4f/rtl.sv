module TopModule (
    input  logic in1,
    input  logic in2,
    output logic out
);

    // The specification requires in1 AND (bubble/inverted in2).
    // The bubble on in2 means we use the logical NOT of in2.
    assign out = in1 & (~in2);

endmodule