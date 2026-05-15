module TopModule (
    input  logic in1,
    input  logic in2,
    output logic out
);

    // The circuit is an AND gate with a bubble on the in2 input.
    // This is equivalent to in1 AND (NOT in2).
    assign out = in1 & (~in2);

endmodule